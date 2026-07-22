import 'dart:async';

import 'package:flutter/services.dart';

import '../app/app_state.dart';
import 'keyboard_service.dart';
import 'native_bridge.dart';
import 'preferences.dart';

class KeyEventListener {
  static const EventChannel _channel = EventChannel(
    "avro/key_events",
  );

  StreamSubscription? _subscription;
  Future<void> _pending = Future.value();

  void start() {
    _subscription = _channel.receiveBroadcastStream().listen((event) {
      if (event is! Map) return;
      final map = Map<String, dynamic>.from(event);
      final key = map["key"] as String?;
      if (key == null) return;

      // EventChannel callbacks are not awaited by Flutter. A small serial
      // queue preserves the exact order of fast global key strokes.
      _pending = _pending.then((_) => _handleKey(key)).catchError((_) {});
    });
  }

  Future<void> _handleKey(String key) async {
    if (key == '__toggle_language__') {
      final enabled = !PreferencesService.instance.banglaMode;
      await LanguageController.instance.setBanglaEnabled(enabled);
      await NativeBridge.instance.toggleLanguage(enabled);
      return;
    }
    if (key == ' ' || key == '\n' || key == '\t') {
      await KeyboardService.instance.commit();
      await NativeBridge.instance.sendText(key);
      return;
    }
    if (key == '\b') {
      final consumed = KeyboardService.instance.backspace();
      if (!consumed) await NativeBridge.instance.sendBackspace();
      return;
    }
    await KeyboardService.instance.processKey(key);
  }

  void stop() {
    _subscription?.cancel();
  }
}
