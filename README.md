# Lock Keyboard

A simple macOS menu bar app that lets you lock and unlock your keyboard with a single click.

## Features

- **Menu bar only** — no Dock icon, no windows, stays out of your way
- **One-click lock/unlock** — click the keyboard icon in the menu bar
- **Mouse always works** — only keyboard input is blocked
- **Emergency unlock** — press `Cmd+Opt+Ctrl+U` to unlock even when locked
- **Safe by design** — quitting the app automatically unlocks; if the app crashes, macOS removes the block

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
3. Click the menu bar icon and select **Lock Keyboard**
4. To unlock, click the icon again and select **Unlock Keyboard**, or press `Cmd+Opt+Ctrl+U`

## How it works

The app uses a `CGEvent` tap to intercept keyboard events system-wide. When locked, all key-down, key-up, and modifier-change events are blocked (returned as `nil`). The mouse is never affected. A health-check timer re-enables the tap every 5 seconds in case macOS silently disables it.

## License

[MIT](LICENSE)
