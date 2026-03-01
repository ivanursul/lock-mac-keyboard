import SwiftUI

@main
struct LockKeyboardApp: App {
    @StateObject private var manager = KeyboardLockManager()

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
            .disabled(!manager.hasAccessibilityPermission)
            .keyboardShortcut("l", modifiers: [.command])

            Divider()

            if manager.isLocked {
                Text("Emergency unlock: Cmd+Opt+Ctrl+U")
                    .font(.caption)
                Divider()
            }

            Button("Quit") {
                manager.unlock()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        } label: {
            Image(systemName: manager.isLocked ? "keyboard.badge.ellipsis" : "keyboard")
        }
    }
}
