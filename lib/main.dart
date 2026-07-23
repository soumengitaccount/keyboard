import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import 'app/app.dart';
import 'services/preferences.dart';
import 'services/dictionary_service.dart';
import 'services/keyboard_service.dart';
import 'services/candidate_window_service.dart';
import 'services/key_event_listener.dart';
import 'services/native_bridge.dart';
import 'services/tray_service.dart';
import 'database/dictionary_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux &&
      Platform.executableArguments.contains('--ibus-engine')) {
    await _runIbusEngine();
    return;
  }

  await PreferencesService.instance.initialize();
  await DictionaryService.instance.load();
  await NativeBridge.instance.toggleLanguage(
    PreferencesService.instance.banglaMode,
  );
  if (NativeBridge.instance.supportsKeyboardInput) {
    KeyEventListener.instance.start();
  }
  await KeyboardService.instance.initialize();
  await CandidateWindowService.instance.initialize();
  // Initialize desktop window APIs
  await Window.initialize();
  await DictionaryDatabase.instance.initialize();

  await windowManager.ensureInitialized();

  if (Platform.isWindows || Platform.isMacOS) {
    try {
      await Window.setEffect(
        effect: WindowEffect.mica,
      );
    } catch (_) {
      // Ignore if unsupported
    }
  }

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1180, 760),
    minimumSize: Size(960, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: "Avro Keyboard",
  );

  await windowManager.waitUntilReadyToShow(
    windowOptions,
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
  await AvroTrayService.instance.initialize();

  runApp(
    const ProviderScope(
      child: AvroApp(),
    ),
  );
  // runApp(
  //   const AvroApp(),
  // );
}

/// IBus starts the packaged executable with `--ibus-engine`. Keep this Dart
/// isolate deliberately headless: it owns the phonetic composition state and
/// communicates with the IBus native runner over the usual platform channels,
/// while the normal executable remains the settings and tray UI.
Future<void> _runIbusEngine() async {
  await PreferencesService.instance.initialize();
  await DictionaryService.instance.load();
  await NativeBridge.instance.toggleLanguage(
    PreferencesService.instance.banglaMode,
  );
  KeyEventListener.instance.start();
  await KeyboardService.instance.initialize();
  runApp(const SizedBox.shrink());
}
