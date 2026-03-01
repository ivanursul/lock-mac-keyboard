import Foundation
import Combine

final class PianoViewModel: ObservableObject {
    @Published var pressedMidiNotes: Set<UInt8> = []

    private let engine = PianoEngine()

    func noteOn(keyCode: Int) {
        guard let note = pianoKeyMapping[keyCode] else { return }
        let midi = note.midiNote

        engine.noteOn(midi)

        DispatchQueue.main.async { [weak self] in
            self?.pressedMidiNotes.insert(midi)
        }
    }

    func noteOff(keyCode: Int) {
        guard let note = pianoKeyMapping[keyCode] else { return }
        let midi = note.midiNote

        engine.noteOff(midi)

        DispatchQueue.main.async { [weak self] in
            self?.pressedMidiNotes.remove(midi)
        }
    }

    func stop() {
        engine.stop()
        DispatchQueue.main.async { [weak self] in
            self?.pressedMidiNotes.removeAll()
        }
    }
}
