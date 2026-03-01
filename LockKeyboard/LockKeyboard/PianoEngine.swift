import AVFoundation

final class PianoEngine {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()

    init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
        } catch {
            print("PianoEngine: failed to start AVAudioEngine: \(error)")
        }

        loadPianoSound()
    }

    private func loadPianoSound() {
        let dlsPath = "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
        let dlsURL = URL(fileURLWithPath: dlsPath)

        do {
            try sampler.loadSoundBankInstrument(at: dlsURL, program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
        } catch {
            print("PianoEngine: failed to load DLS instrument: \(error)")
        }
    }

    func noteOn(_ midiNote: UInt8, velocity: UInt8 = 100) {
        sampler.startNote(midiNote, withVelocity: velocity, onChannel: 0)
    }

    func noteOff(_ midiNote: UInt8) {
        sampler.stopNote(midiNote, onChannel: 0)
    }

    func stop() {
        engine.stop()
    }
}
