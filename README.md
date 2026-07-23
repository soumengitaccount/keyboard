# Avro Keyboard for Flutter Desktop

A desktop-first Bangla phonetic keyboard inspired by the classic Avro control bar. It has a Flutter configuration window, resident system tray, layout viewer, candidate preview, persisted preferences, and a native platform boundary for system-wide input and Unicode output.

## Project layout

```text
lib/
  app/                 theme and application shell
  engine/              phonetic parser, conjuncts, candidates, backspace
  screens/             dashboard, layout viewer, settings
  services/            preferences, keyboard state, native channel
  widgets/             desktop top bar, sidebar, setting cards, candidates
windows/runner/        WH_KEYBOARD_LL hook and SendInput Unicode injection
macos/Runner/          CGEventTap hook and CGEvent Unicode injection
linux/runner/          GTK runner and IBus IME bridge
packaging/             Inno Setup and Debian packaging templates
```

## Native input flow

```text
global key hook → avro/key_events EventChannel → Dart phonetic engine
                → avro/native composition → active app
```

On Windows the runner uses `SetWindowsHookEx(WH_KEYBOARD_LL)` and blocks the source Latin key only while Bangla mode is enabled. It ignores its own `LLKHF_INJECTED` events, avoiding a hook/injection loop. Unicode output uses `SendInput` with `KEYEVENTF_UNICODE`, which works with Word, Notepad, Chromium browsers, and other standard text controls. The runner keeps both channels alive for the application's lifetime, serializes key delivery in Dart, and handles `Ctrl + Alt + B` as the global Bangla/English toggle.

On macOS the runner uses a session `CGEventTap`; macOS will prompt the user to grant **Input Monitoring** permission. Unicode text is posted through `CGEvent.keyboardSetUnicodeString`.

All platforms now render Bengali while the word is being typed. IBus exposes it
as native preedit. The Windows and macOS hooks replace the provisional text on
each keypress, then finalise it on a delimiter, language toggle, or candidate
selection. Backspace continues to edit the original Latin phonetic buffer.

## Run

```bash
flutter pub get
flutter run -d windows
# or: flutter run -d macos
```

Use the Bangla pill in the top bar, the tray menu, or `Ctrl + Alt + B` to switch languages. Closing/minimizing the settings window should be paired with your preferred hide-to-tray policy for a release build.

## Linux and Wayland

Linux uses an **IBus** engine, not a global hook. When IBus selects Bangla
Avro, it launches the packaged executable with `--ibus-engine`; the headless
Flutter isolate runs the existing Dart phonetic engine. IBus delivers only
keys from the focused text field, shows the rendered composition as preedit,
and receives committed Unicode text back through the native channel. This
works on Wayland as well as X11 without bypassing compositor security.

Build with IBus development files available:

```bash
sudo apt install libibus-1.0-dev
flutter build linux --release
```

The Debian package installs `bangla-avro.xml` in IBus's component directory.
After installation, restart IBus and add **Bangla Avro** from IBus Preferences,
or select it for the current session with `ibus engine bangla-avro`.

## Important production work

- Keep the native hook thin: never do Dart work inside the OS hook callback.
- Extend the baseline phonetic parser with Avro's complete exception/context table and a golden corpus generated from Avro-compatible fixtures.
- Add a hide-to-tray close policy for release builds.
- Code-sign macOS and Windows distributions; document macOS Input Monitoring permission.
- Test in Word, Notepad, Chromium, Electron, rich-text editors, and elevated Windows apps (an unelevated hook cannot inject into higher-integrity targets).
