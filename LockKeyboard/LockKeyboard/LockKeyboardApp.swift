import SwiftUI

@main
struct LockKeyboardApp: App {
    @StateObject private var manager = KeyboardLockManager()
    private let pianoWindowController = PianoWindowController()

    var body: some Scene {
        MenuBarExtra {
            if !manager.hasAccessibilityPermission {
                Button("Grant Accessibility Permission...") {
                    manager.requestAccessibilityPermission()
                }
            }

            Button(manager.isLocked ? "Unlock Keyboard" : "Lock Keyboard") {
                manager.toggle()
            }
            .disabled(!manager.hasAccessibilityPermission || manager.isPiano)
            .keyboardShortcut("l", modifiers: [.command])

            Button(manager.isPiano ? "Stop Piano Mode" : "Piano Mode") {
                if manager.isPiano {
                    manager.stopPianoMode()
                    pianoWindowController.close()
                } else {
                    let vm = pianoWindowController.show()
                    manager.startPianoMode(viewModel: vm)
                }
            }
            .disabled(!manager.hasAccessibilityPermission || manager.isLocked)
            .keyboardShortcut("p", modifiers: [.command])

            Divider()

            if manager.mode != .normal {
                Text("Emergency unlock: Cmd+Opt+Ctrl+U")
                    .font(.caption)
                Divider()
            }

            Button("Quit") {
                if manager.isPiano {
                    pianoWindowController.close()
                }
                manager.stopAll()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        } label: {
            Image(systemName: menuBarIcon)
        }
        .onChange(of: manager.mode) { _, newMode in
            // If emergency unlock happened while piano was showing, close window
            if newMode == .normal {
                pianoWindowController.close()
            }
        }
    }

    private var menuBarIcon: String {
        switch manager.mode {
        case .normal: return "keyboard"
        case .locked: return "keyboard.badge.ellipsis"
        case .piano: return "pianokeys"
        }
    }
}
