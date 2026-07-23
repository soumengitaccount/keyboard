import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/keyboard_service.dart';
import '../services/native_bridge.dart';
import '../services/preferences.dart';

/// Application-wide state exposed to widgets. Native input remains in
/// [KeyboardService], while Riverpod provides a single reactive access point
/// for the Flutter desktop UI.
final keyboardServiceProvider = ChangeNotifierProvider<KeyboardService>(
  (ref) => KeyboardService.instance,
);

final languageControllerProvider = ChangeNotifierProvider<LanguageController>(
  (ref) => LanguageController.instance,
);

class LanguageController extends ChangeNotifier {
  LanguageController._();

  static final LanguageController instance = LanguageController._();

  bool _banglaEnabled = PreferencesService.instance.banglaMode;

  bool get banglaEnabled => _banglaEnabled;

  Future<void> setBanglaEnabled(bool value) async {
    if (_banglaEnabled == value) return;
    if (!value) {
      await KeyboardService.instance.commit();
    }
    _banglaEnabled = value;
    notifyListeners();
    await PreferencesService.instance.setBanglaMode(value);
    await NativeBridge.instance.toggleLanguage(value);
  }
}

final themeControllerProvider =
    ChangeNotifierProvider<ThemeController>((ref) => ThemeController());

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = _fromStored(PreferencesService.instance.themeMode);

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await PreferencesService.instance.setThemeMode(_toStored(mode));
  }

  static ThemeMode _fromStored(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toStored(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
