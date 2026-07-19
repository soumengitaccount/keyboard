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
import 'database/dictionary_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // extarnally added
  await PreferencesService.instance.initialize();
  await DictionaryService.instance.load();
  await KeyboardService.instance.initialize();
  KeyEventListener().start();
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

  runApp(
    const ProviderScope(
      child: AvroApp(),
    ),
  );
  // runApp(
  //   const AvroApp(),
  // );
}
