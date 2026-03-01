import Cocoa
import Combine

enum AppMode {
    case normal
    case locked
    case piano
}

final class KeyboardLockManager: ObservableObject {
    @Published var mode: AppMode = .normal
    @Published var hasAccessibilityPermission = false

    var isLocked: Bool { mode == .locked }
    var isPiano: Bool { mode == .piano }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var healthCheckTimer: Timer?
    private var permissionPollTimer: Timer?

    // Piano mode: the view model is set externally by the app
    var pianoViewModel: PianoViewModel?

    init() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        if !hasAccessibilityPermission {
            startPermissionPolling()
        }
    }

    deinit {
        stopAll()
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
        guard mode == .normal, hasAccessibilityPermission else { return }
        startEventTap()
        mode = .locked
    }

    func unlock() {
        tearDownEventTap()
        pianoViewModel = nil
        mode = .normal
    }

    // MARK: - Piano Mode

    func startPianoMode(viewModel: PianoViewModel) {
        guard mode == .normal, hasAccessibilityPermission else { return }
        pianoViewModel = viewModel
        startEventTap()
        mode = .piano
    }

    func stopPianoMode() {
        pianoViewModel?.stop()
        tearDownEventTap()
        pianoViewModel = nil
        mode = .normal
    }

    /// Stops everything (for quit cleanup)
    func stopAll() {
        switch mode {
        case .piano:
            stopPianoMode()
        case .locked:
            unlock()
        case .normal:
            break
        }
    }

    // MARK: - Event Tap

    private func startEventTap() {
        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

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

                guard let userInfo else { return nil }
                let manager = Unmanaged<KeyboardLockManager>.fromOpaque(userInfo).takeUnretainedValue()

                // Emergency unlock: Cmd+Opt+Ctrl+U (works in both locked and piano mode)
                let flags = event.flags
                let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
                let isEmergencyCombo =
                    flags.contains(.maskCommand) &&
                    flags.contains(.maskAlternate) &&
                    flags.contains(.maskControl) &&
                    keyCode == 32 // 'U' key
                if isEmergencyCombo && type == .keyDown {
                    DispatchQueue.main.async {
                        manager.stopAll()
                    }
                    return Unmanaged.passRetained(event)
                }

                // Piano mode: route keys to piano
                if manager.mode == .piano {
                    if type == .keyDown {
                        manager.pianoViewModel?.noteOn(keyCode: keyCode)
                    } else if type == .keyUp {
                        manager.pianoViewModel?.noteOff(keyCode: keyCode)
                    }
                    // Block the event from reaching other apps
                    return nil
                }

                // Locked mode: block everything
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

        startHealthCheck()
    }

    private func tearDownEventTap() {
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
