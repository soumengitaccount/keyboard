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

  /// Windows and macOS runners register the native hook channel. Linux needs
  /// an IBus/Fcitx integration instead of a raw global hook (especially on
  /// Wayland), so never invoke an unregistered channel there.
  bool get supportsGlobalKeyboard => Platform.isWindows || Platform.isMacOS;

  // ------------------------------------------------------------
  // Enable global keyboard listener
  // ------------------------------------------------------------

  Future<bool> enableKeyboard() async {
    if (!supportsGlobalKeyboard) return false;
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
    if (!supportsGlobalKeyboard) return false;
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
    if (!supportsGlobalKeyboard) return;
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
    if (!supportsGlobalKeyboard) return;
    try {
      await _channel.invokeMethod<void>('sendBackspace');
    } catch (e) {
      _logger.e('Backspace injection failed', error: e);
    }
  }

  // ------------------------------------------------------------
  // Change keyboard layout
  // ------------------------------------------------------------

  Future<void> changeLayout(
    String layout,
  ) async {
    if (!supportsGlobalKeyboard) return;
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
    if (!supportsGlobalKeyboard) return;
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
    if (!supportsGlobalKeyboard) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        "status",
      );

      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
