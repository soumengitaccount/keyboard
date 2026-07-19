import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import 'theme.dart';

class AvroApp extends StatelessWidget {
  const AvroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Avro Keyboard",
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
