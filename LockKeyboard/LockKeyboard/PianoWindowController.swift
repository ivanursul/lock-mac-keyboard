import Cocoa
import SwiftUI

final class PianoWindowController {
    private var window: NSWindow?
    private(set) var viewModel: PianoViewModel?

    func show() -> PianoViewModel {
        let vm = PianoViewModel()
        viewModel = vm

        let pianoView = PianoView(viewModel: vm)
        let hostingView = NSHostingView(rootView: pianoView)

        guard let screen = NSScreen.main else {
            return vm
        }

        let frame = screen.visibleFrame

        let win = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.level = .floating
        win.isOpaque = true
        win.backgroundColor = .black
        win.contentView = hostingView
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.makeKeyAndOrderFront(nil)

        window = win
        return vm
    }

    func close() {
        viewModel?.stop()
        window?.orderOut(nil)
        window = nil
        viewModel = nil
    }
}
