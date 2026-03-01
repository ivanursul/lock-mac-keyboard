import Foundation

struct PianoNote {
    let midiNote: UInt8
    let name: String
}

// macOS virtual key codes → MIDI notes (2.5 octaves, C3–E5)
// Lower octave: bottom row = white keys, home row between = black keys
// Upper octave: Q row = white keys, number row between = black keys
// Extended: I, 9, O, 0, P

let pianoKeyMapping: [Int: PianoNote] = [
    // Lower octave (C3–B3)
    6:  PianoNote(midiNote: 48, name: "C3"),   // Z
    1:  PianoNote(midiNote: 49, name: "C#3"),  // S
    7:  PianoNote(midiNote: 50, name: "D3"),   // X
    2:  PianoNote(midiNote: 51, name: "D#3"),  // D
    8:  PianoNote(midiNote: 52, name: "E3"),   // C
    9:  PianoNote(midiNote: 53, name: "F3"),   // V
    5:  PianoNote(midiNote: 54, name: "F#3"),  // G
    11: PianoNote(midiNote: 55, name: "G3"),   // B
    4:  PianoNote(midiNote: 56, name: "G#3"),  // H
    45: PianoNote(midiNote: 57, name: "A3"),   // N
    38: PianoNote(midiNote: 58, name: "A#3"),  // J
    46: PianoNote(midiNote: 59, name: "B3"),   // M

    // Upper octave (C4–B4)
    12: PianoNote(midiNote: 60, name: "C4"),   // Q
    19: PianoNote(midiNote: 61, name: "C#4"),  // 2
    13: PianoNote(midiNote: 62, name: "D4"),   // W
    20: PianoNote(midiNote: 63, name: "D#4"),  // 3
    14: PianoNote(midiNote: 64, name: "E4"),   // E
    15: PianoNote(midiNote: 65, name: "F4"),   // R
    23: PianoNote(midiNote: 66, name: "F#4"),  // 5
    17: PianoNote(midiNote: 67, name: "G4"),   // T
    22: PianoNote(midiNote: 68, name: "G#4"),  // 6
    16: PianoNote(midiNote: 69, name: "A4"),   // Y
    26: PianoNote(midiNote: 70, name: "A#4"),  // 7
    32: PianoNote(midiNote: 71, name: "B4"),   // U  (keyCode 32 is also emergency unlock key)

    // Extended (C5–E5)
    34: PianoNote(midiNote: 72, name: "C5"),   // I
    25: PianoNote(midiNote: 73, name: "C#5"),  // 9
    31: PianoNote(midiNote: 74, name: "D5"),   // O
    29: PianoNote(midiNote: 75, name: "D#5"),  // 0
    35: PianoNote(midiNote: 76, name: "E5"),   // P
]
