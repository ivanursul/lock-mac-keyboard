import SwiftUI

struct PianoView: View {
    @ObservedObject var viewModel: PianoViewModel

    // All MIDI notes in our range, grouped by octave
    // C3(48)..E5(76) = 29 notes total
    // White keys: C, D, E, F, G, A, B
    // Black keys: C#, D#, F#, G#, A#

    private static let whiteNoteOffsets: [Int] = [0, 2, 4, 5, 7, 9, 11] // semitones within octave
    private static let blackNoteOffsets: [Int] = [1, 3, 6, 8, 10]       // semitones within octave

    private struct KeyInfo: Identifiable {
        let id: UInt8 // MIDI note
        let isBlack: Bool
        let label: String
    }

    private var whiteKeys: [KeyInfo] {
        var keys: [KeyInfo] = []
        for midi in UInt8(48)...UInt8(76) {
            let offset = Int(midi) % 12
            if Self.whiteNoteOffsets.contains(offset) {
                let name = noteName(midi)
                keys.append(KeyInfo(id: midi, isBlack: false, label: name))
            }
        }
        return keys
    }

    private var blackKeys: [KeyInfo] {
        var keys: [KeyInfo] = []
        for midi in UInt8(48)...UInt8(76) {
            let offset = Int(midi) % 12
            if Self.blackNoteOffsets.contains(offset) {
                let name = noteName(midi)
                keys.append(KeyInfo(id: midi, isBlack: true, label: name))
            }
        }
        return keys
    }

    private func noteName(_ midi: UInt8) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(midi) / 12 - 1
        let note = Int(midi) % 12
        return "\(names[note])\(octave)"
    }

    // Returns the keyboard letter for a given MIDI note
    private func keyLabel(_ midi: UInt8) -> String? {
        for (_, note) in pianoKeyMapping {
            if note.midiNote == midi {
                // Find the key character from the keyCode
                return keyCharForMidi(midi)
            }
        }
        return nil
    }

    private func keyCharForMidi(_ midi: UInt8) -> String? {
        let midiToChar: [UInt8: String] = [
            48: "Z", 49: "S", 50: "X", 51: "D", 52: "C", 53: "V",
            54: "G", 55: "B", 56: "H", 57: "N", 58: "J", 59: "M",
            60: "Q", 61: "2", 62: "W", 63: "3", 64: "E", 65: "R",
            66: "5", 67: "T", 68: "6", 69: "Y", 70: "7", 71: "U",
            72: "I", 73: "9", 74: "O", 75: "0", 76: "P",
        ]
        return midiToChar[midi]
    }

    // Black key position relative to white key index
    private func blackKeyPosition(for midi: UInt8, whiteKeyCount: Int, geoWidth: CGFloat) -> CGFloat? {
        let whiteKeyWidth = geoWidth / CGFloat(whiteKeyCount)
        // Find which white key this black key sits between
        // Count white keys from C3 up to this black key's position
        let offset = Int(midi) % 12
        let octaveStart = (Int(midi) / 12) * 12
        let octaveBase = octaveStart // e.g., 48 for C3, 60 for C4, 72 for C5

        // Count all white keys from MIDI 48 up to octaveBase
        var whitesBefore = 0
        for m in 48..<octaveBase {
            if Self.whiteNoteOffsets.contains(m % 12) {
                whitesBefore += 1
            }
        }

        // Position within octave
        let positionInOctave: CGFloat
        switch offset {
        case 1:  positionInOctave = 0.75   // C# between C and D
        case 3:  positionInOctave = 1.75   // D# between D and E
        case 6:  positionInOctave = 3.75   // F# between F and G
        case 8:  positionInOctave = 4.75   // G# between G and A
        case 10: positionInOctave = 5.75   // A# between A and B
        default: return nil
        }

        let x = (CGFloat(whitesBefore) + positionInOctave) * whiteKeyWidth
        return x
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Background
                Color(red: 0.15, green: 0.15, blue: 0.25)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Title area
                    Text("Piano")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 20)

                    // Piano keys
                    let whites = whiteKeys
                    let blacks = blackKeys
                    let pianoWidth = geo.size.width * 0.9
                    let pianoHeight = geo.size.height * 0.6
                    let whiteKeyWidth = pianoWidth / CGFloat(whites.count)
                    let blackKeyWidth = whiteKeyWidth * 0.6
                    let blackKeyHeight = pianoHeight * 0.6

                    ZStack(alignment: .topLeading) {
                        // White keys
                        HStack(spacing: 0) {
                            ForEach(whites) { key in
                                let isPressed = viewModel.pressedMidiNotes.contains(key.id)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isPressed ? Color.yellow : Color.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)

                                    VStack {
                                        Spacer()
                                        if let char = keyCharForMidi(key.id) {
                                            Text(char)
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(isPressed ? .orange : .gray)
                                        }
                                        Text(key.label)
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundColor(.gray.opacity(0.7))
                                            .padding(.bottom, 12)
                                    }
                                }
                                .frame(width: whiteKeyWidth - 2, height: pianoHeight)
                                .padding(.horizontal, 1)
                            }
                        }

                        // Black keys
                        ForEach(blacks) { key in
                            let isPressed = viewModel.pressedMidiNotes.contains(key.id)
                            if let xPos = blackKeyPosition(for: key.id, whiteKeyCount: whites.count, geoWidth: pianoWidth) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(isPressed ? Color.orange : Color(red: 0.15, green: 0.15, blue: 0.2))
                                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 3)

                                    VStack {
                                        Spacer()
                                        if let char = keyCharForMidi(key.id) {
                                            Text(char)
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundColor(isPressed ? .white : .gray)
                                                .padding(.bottom, 8)
                                        }
                                    }
                                }
                                .frame(width: blackKeyWidth, height: blackKeyHeight)
                                .offset(x: xPos - blackKeyWidth / 2)
                            }
                        }
                    }
                    .frame(width: pianoWidth, height: pianoHeight)
                    .frame(maxWidth: .infinity)

                    Spacer()

                    Text("Press keyboard keys to play! Parent: use menu bar to exit.")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 40)
                }
            }
        }
    }
}
