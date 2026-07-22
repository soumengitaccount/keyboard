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
linux/runner/          GTK runner (see Linux note below)
packaging/             Inno Setup and Debian packaging templates
```

## Native input flow

```text
global key hook → avro/key_events EventChannel → Dart phonetic engine
                → avro/native sendText → OS Unicode injection → active app
```

On Windows the runner uses `SetWindowsHookEx(WH_KEYBOARD_LL)` and blocks the source Latin key only while Bangla mode is enabled. It ignores its own `LLKHF_INJECTED` events, avoiding a hook/injection loop. Unicode output uses `SendInput` with `KEYEVENTF_UNICODE`, which works with Word, Notepad, Chromium browsers, and other standard text controls. The runner keeps both channels alive for the application's lifetime, serializes key delivery in Dart, and handles `Ctrl + Alt + B` as the global Bangla/English toggle.

On macOS the runner uses a session `CGEventTap`; macOS will prompt the user to grant **Input Monitoring** permission. Unicode text is posted through `CGEvent.keyboardSetUnicodeString`.

## Run

```bash
flutter pub get
flutter run -d windows
# or: flutter run -d macos
```

Use the Bangla pill in the top bar, the tray menu, or `Ctrl + Alt + B` to switch languages. Closing/minimizing the settings window should be paired with your preferred hide-to-tray policy for a release build.

## Linux and Wayland

Global keyboard interception is not universally allowed on Linux. X11 can support it through XInput2/XGrabKey, but modern Wayland compositors deliberately prevent arbitrary apps from reading other applications' keys. For a production Linux build, use an IME framework such as **IBus** or **Fcitx5** (or a compositor-specific input portal), then retain this Flutter app as the settings/tray UI. Do not use a raw global hook as a Wayland fallback.

## Important production work

- Keep the native hook thin: never do Dart work inside the OS hook callback.
- Add a native composition protocol (replace the old composition before injecting the new one) for character-by-character Avro-style output. The included implementation commits at word boundaries, which is safer for cross-app interoperability.
- Extend the baseline phonetic parser with Avro's complete exception/context table and a golden corpus generated from Avro-compatible fixtures.
- Add a hide-to-tray close policy for release builds.
- Code-sign macOS and Windows distributions; document macOS Input Monitoring permission.
- Test in Word, Notepad, Chromium, Electron, rich-text editors, and elevated Windows apps (an unelevated hook cannot inject into higher-integrity targets).
