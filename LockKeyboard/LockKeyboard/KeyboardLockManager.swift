import Cocoa
import Combine

final class KeyboardLockManager: ObservableObject {
    @Published var isLocked = false
    @Published var hasAccessibilityPermission = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var healthCheckTimer: Timer?
    private var permissionPollTimer: Timer?

    init() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        if !hasAccessibilityPermission {
            startPermissionPolling()
        }
    }

    deinit {
        unlock()
        permissionPollTimer?.invalidate()
    }

    // MARK: - Lock / Unlock

    func toggle() {
        if isLocked {
            unlock()
        } else {
            lock()
        }
    }

    func lock() {
        guard !isLocked, hasAccessibilityPermission else { return }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        // Store a raw pointer to self for the C callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo -> Unmanaged<CGEvent>? in
                // If the tap is disabled by the system, re-enable it
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    return Unmanaged.passRetained(event)
                }

                // Emergency unlock: Cmd+Opt+Ctrl+U
                let flags = event.flags
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let isEmergencyCombo =
                    flags.contains(.maskCommand) &&
                    flags.contains(.maskAlternate) &&
                    flags.contains(.maskControl) &&
                    keyCode == 32 // 'U' key
                if isEmergencyCombo && type == .keyDown {
                    if let userInfo = userInfo {
                        let manager = Unmanaged<KeyboardLockManager>.fromOpaque(userInfo).takeUnretainedValue()
                        DispatchQueue.main.async {
                            manager.unlock()
                        }
                    }
                    return Unmanaged.passRetained(event)
                }

                // Block the event
                return nil
            },
            userInfo: selfPtr
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isLocked = true
        startHealthCheck()
    }

    func unlock() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            CFMachPortInvalidate(tap)
        }
        eventTap = nil
        runLoopSource = nil
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil

        isLocked = false
    }

    // MARK: - Health Check

    private func startHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self, let tap = self.eventTap else { return }
            if !CGEvent.tapIsEnabled(tap: tap) {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
    }

    // MARK: - Accessibility Permission

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        startPermissionPolling()
    }

    private func startPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            if AXIsProcessTrusted() {
                self.hasAccessibilityPermission = true
                timer.invalidate()
                self.permissionPollTimer = nil
            }
        }
    }
}
