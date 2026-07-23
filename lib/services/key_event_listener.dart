import 'dart:async';

import 'package:flutter/services.dart';

import '../app/app_state.dart';
import 'keyboard_service.dart';
import 'native_bridge.dart';
import 'preferences.dart';

class KeyEventListener {
  KeyEventListener._();

  static final KeyEventListener instance = KeyEventListener._();

  static const EventChannel _channel = EventChannel(
    "avro/key_events",
  );

  StreamSubscription? _subscription;
  Future<void> _pending = Future.value();

  void start() {
    if (_subscription != null) return;
    _subscription = _channel.receiveBroadcastStream().listen((event) {
      if (event is! Map) return;
      final map = Map<String, dynamic>.from(event);
      if (map['action'] == 'reset') {
        _pending = _pending
            .then((_) => KeyboardService.instance.cancelComposition())
            .catchError((_) {});
        return;
      }
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
      return;
    }
    if (key == '__cancel_composition__') {
      await KeyboardService.instance.cancelComposition();
      return;
    }
    if (key == ' ' || key == '\n' || key == '\t') {
      await KeyboardService.instance.commit();
      await NativeBridge.instance.sendKey(switch (key) {
        ' ' => 'space',
        '\n' => 'enter',
        '\t' => 'tab',
        _ => throw StateError('Unexpected word boundary'),
      });
      return;
    }
    if (key == '\b') {
      final consumed = KeyboardService.instance.backspace();
      if (consumed) {
        await NativeBridge.instance.updateComposition(
          KeyboardService.instance.preview,
        );
      } else {
        await NativeBridge.instance.sendBackspace();
      }
      return;
    }

    // Native Windows sends the printable character after applying the active
    // layout. The phonetic engine consumes Latin letters; every other printable
    // character is a delimiter that must be emitted after the composition.
    if (RegExp(r'^[A-Za-z]+$').hasMatch(key)) {
      await KeyboardService.instance.processKey(key);
      await NativeBridge.instance.updateComposition(
        KeyboardService.instance.preview,
      );
    } else {
      await KeyboardService.instance.commit();
      await NativeBridge.instance.sendText(key);
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
