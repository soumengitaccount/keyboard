import 'dart:async';

import 'package:flutter/services.dart';

import 'keyboard_service.dart';
import 'native_bridge.dart';

class KeyEventListener {
  static const EventChannel _channel = EventChannel(
    "avro/key_events",
  );

  StreamSubscription? _subscription;

  void start() {
    _subscription = _channel.receiveBroadcastStream().listen((event) {
      final map = Map<String, dynamic>.from(event);

      final key = map["key"];

      if (key != null) {
        if (key == ' ' || key == '\n' || key == '\t') {
          KeyboardService.instance.commit().then((_) {
            NativeBridge.instance.sendText(key);
          });
        } else if (key == '\b') {
          KeyboardService.instance.backspace();
        } else {
          KeyboardService.instance.processKey(key);
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
  }
}
