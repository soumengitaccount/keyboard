import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class NativeBridge {
  NativeBridge._();

  static final NativeBridge instance = NativeBridge._();

  final Logger _logger = Logger();

  static const MethodChannel _channel = MethodChannel(
    "avro/native",
  );

  /// Windows and macOS use a native global hook. Linux uses the IBus engine
  /// registered by the Linux runner; it receives keys only from the active
  /// input context, not from other applications.
  bool get supportsGlobalKeyboard => Platform.isWindows || Platform.isMacOS;

  /// Linux has a keyboard input path only in the headless process that IBus
  /// launches. The normal Linux executable remains a settings/tray UI and
  /// must not pretend it can inspect global input.
  bool get supportsKeyboardInput =>
      supportsGlobalKeyboard ||
      (Platform.isLinux &&
          Platform.executableArguments.contains('--ibus-engine'));

  // ------------------------------------------------------------
  // Enable global keyboard listener
  // ------------------------------------------------------------

  Future<bool> enableKeyboard() async {
    if (!supportsKeyboardInput) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        "enableKeyboard",
      );

      return result ?? false;
    } catch (e) {
      _logger.e(
        "Enable keyboard failed",
        error: e,
      );

      return false;
    }
  }

  // ------------------------------------------------------------
  // Disable keyboard listener
  // ------------------------------------------------------------

  Future<bool> disableKeyboard() async {
    if (!supportsKeyboardInput) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        "disableKeyboard",
      );

      return result ?? false;
    } catch (e) {
      _logger.e(
        "Disable keyboard failed",
        error: e,
      );

      return false;
    }
  }

  // ------------------------------------------------------------
  // Send Unicode Bangla text
  // ------------------------------------------------------------

  Future<void> sendText(
    String text,
  ) async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod(
        "sendText",
        {
          "text": text,
        },
      );
    } catch (e) {
      _logger.e(
        "Text injection failed",
        error: e,
      );
    }
  }

  /// Sends a physical Backspace to the foreground application. This is used
  /// only when there is no uncommitted phonetic composition to edit in Dart.
  Future<void> sendBackspace() async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod<void>('sendBackspace');
    } catch (e) {
      _logger.e('Backspace injection failed', error: e);
    }
  }

  /// Sends a non-text editing key through the native runner. Word boundaries
  /// use real virtual-key events so Enter and Tab retain their normal behavior
  /// in controls that do not treat Unicode control characters as commands.
  Future<void> sendKey(String key) async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod<bool>('sendKey', {'key': key});
    } catch (e) {
      _logger.e('Control-key injection failed', error: e);
    }
  }

  // ------------------------------------------------------------
  // Change keyboard layout
  // ------------------------------------------------------------

  Future<void> changeLayout(
    String layout,
  ) async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod(
        "changeLayout",
        {
          "layout": layout,
        },
      );
    } catch (e) {
      _logger.e(
        "Layout change failed",
        error: e,
      );
    }
  }

  // ------------------------------------------------------------
  // Toggle Bangla / English mode
  // ------------------------------------------------------------

  Future<void> toggleLanguage(
    bool bangla,
  ) async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod(
        "toggleLanguage",
        {
          "bangla": bangla,
        },
      );
    } catch (e) {
      _logger.e(
        "Language toggle failed",
        error: e,
      );
    }
  }

  // ------------------------------------------------------------
  // Native status check
  // ------------------------------------------------------------

  Future<bool> isAvailable() async {
    if (!supportsKeyboardInput) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        "status",
      );

      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Publishes the current Bengali composition to the active text target.
  ///
  /// Linux uses IBus preedit. Windows and macOS replace their provisional
  /// injected text, so the user sees each phonetic key press immediately.
  Future<void> updateComposition(String text) async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod<void>('updateComposition', {'text': text});
    } catch (e) {
      _logger.e('Composition update failed', error: e);
    }
  }

  /// Finalizes the current composition, optionally replacing it with a
  /// corrected or candidate value before it becomes permanent text.
  Future<void> commitComposition(String text) async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod<void>('commitComposition', {'text': text});
    } catch (e) {
      _logger.e('Composition commit failed', error: e);
    }
  }

  /// Cancels the current provisional composition without changing text that
  /// was committed before it.
  Future<void> cancelComposition() async {
    if (!supportsKeyboardInput) return;
    try {
      await _channel.invokeMethod<void>('cancelComposition');
    } catch (e) {
      _logger.e('Composition cancel failed', error: e);
    }
  }
}
