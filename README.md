# Lock Keyboard

A macOS menu bar app built for parents of toddlers. When your little one wants to bang on the keyboard, you can either lock it completely or switch to **Piano Mode** — turning the keyboard into a musical instrument with real piano sounds.

## Features

- **Menu bar only** — no Dock icon, no windows, stays out of your way
- **One-click lock/unlock** — click the keyboard icon in the menu bar
- **Piano Mode** — a full-screen piano UI where keyboard keys play real piano notes (2.5 octaves, C3-E5)
- **Kid-friendly piano** — colorful keys with labels, pressed-key highlighting, and built-in macOS instrument sounds
- **Mouse always works** — only keyboard input is blocked
- **Emergency unlock** — press `Cmd+Opt+Ctrl+U` to unlock even when locked or in piano mode
- **Safe by design** — quitting the app automatically unlocks; if the app crashes, macOS removes the block

## Why?

My toddler loves pressing keys on my MacBook. Instead of fighting it, I built this app so he can safely play — either with the keyboard fully locked (so nothing gets typed into the wrong place) or in Piano Mode where every key press makes a musical sound. The piano fills the screen but leaves the menu bar accessible so I can turn it off when needed.

## Piano Mode

Press keyboard keys to play piano notes:

| Row | Keys | Notes |
|-----|------|-------|
| Bottom row | Z X C V B N M | C3 D3 E3 F3 G3 A3 B3 (white keys) |
| Home row | S D G H J | C#3 D#3 F#3 G#3 A#3 (black keys) |
| Q row | Q W E R T Y U | C4 D4 E4 F4 G4 A4 B4 (white keys) |
| Number row | 2 3 5 6 7 | C#4 D#4 F#4 G#4 A#4 (black keys) |
| Extended | I O P | C5 D5 E5 |

Uses the built-in macOS General MIDI instrument bank — no extra files needed.

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permission (prompted on first launch)

## Installation

### Download

Grab the latest `.app` from [Releases](../../releases).

### Build from source

```bash
git clone https://github.com/ivanursul/lock-mac-keyboard.git
cd lock-mac-keyboard/LockKeyboard
xcodebuild -project LockKeyboard.xcodeproj -scheme LockKeyboard -configuration Release build
```

The built app will be in `~/Library/Developer/Xcode/DerivedData/LockKeyboard-*/Build/Products/Release/LockKeyboard.app`.

## Usage

1. Launch the app — a keyboard icon appears in your menu bar
2. Grant **Accessibility permission** when prompted (System Settings > Privacy & Security > Accessibility)
3. Click the menu bar icon:
   - **Lock Keyboard** — blocks all keyboard input
   - **Piano Mode** — opens full-screen piano, keys play notes
4. To exit, click the menu bar icon and select **Unlock Keyboard** or **Stop Piano Mode**, or press `Cmd+Opt+Ctrl+U`

## How it works

The app uses a `CGEvent` tap to intercept keyboard events system-wide. In lock mode, all events are blocked. In piano mode, key events are routed to an `AVAudioEngine` + `AVAudioUnitSampler` that plays MIDI notes using the built-in macOS DLS instrument bank. The mouse is never affected. A health-check timer re-enables the tap every 5 seconds in case macOS silently disables it.

## License

[MIT](LICENSE)
