import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';
import '../screens/home/home_screen.dart';
import 'theme.dart';

class AvroApp extends ConsumerWidget {
  const AvroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: "Avro Keyboard",
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ref.watch(themeControllerProvider).mode,
      home: const HomeScreen(),
    );
  }
}
