import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class NativeBridge {
  NativeBridge._();

  static final NativeBridge instance = NativeBridge._();

  final Logger _logger = Logger();

  static const MethodChannel _channel = MethodChannel(
    "avro/native",
  );

  // ------------------------------------------------------------
  // Enable global keyboard listener
  // ------------------------------------------------------------

  Future<bool> enableKeyboard() async {
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

  // ------------------------------------------------------------
  // Change keyboard layout
  // ------------------------------------------------------------

  Future<void> changeLayout(
    String layout,
  ) async {
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
