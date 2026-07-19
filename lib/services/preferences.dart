import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();

  static final PreferencesService instance = PreferencesService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
        "PreferencesService not initialized",
      );
    }

    return _prefs!;
  }

  // ------------------------------------------------------------
  // Keyboard Enabled
  // ------------------------------------------------------------

  bool get keyboardEnabled {
    return prefs.getBool(
          "keyboard_enabled",
        ) ??
        true;
  }

  Future<void> setKeyboardEnabled(
    bool value,
  ) async {
    await prefs.setBool(
      "keyboard_enabled",
      value,
    );
  }

  // ------------------------------------------------------------
  // Bangla Mode
  // ------------------------------------------------------------

  bool get banglaMode {
    return prefs.getBool(
          "bangla_mode",
        ) ??
        true;
  }

  Future<void> setBanglaMode(
    bool value,
  ) async {
    await prefs.setBool(
      "bangla_mode",
      value,
    );
  }

  // ------------------------------------------------------------
  // Keyboard Layout
  // ------------------------------------------------------------

  String get layout {
    return prefs.getString(
          "layout",
        ) ??
        "Avro Phonetic";
  }

  Future<void> setLayout(
    String value,
  ) async {
    await prefs.setString(
      "layout",
      value,
    );
  }

  // ------------------------------------------------------------
  // Startup With System
  // ------------------------------------------------------------

  bool get startupEnabled {
    return prefs.getBool(
          "startup_enabled",
        ) ??
        true;
  }

  Future<void> setStartupEnabled(
    bool value,
  ) async {
    await prefs.setBool(
      "startup_enabled",
      value,
    );
  }

  // ------------------------------------------------------------
  // Floating Preview
  // ------------------------------------------------------------

  bool get floatingPreview {
    return prefs.getBool(
          "floating_preview",
        ) ??
        true;
  }

  Future<void> setFloatingPreview(
    bool value,
  ) async {
    await prefs.setBool(
      "floating_preview",
      value,
    );
  }

  // ------------------------------------------------------------
  // Candidate Suggestions
  // ------------------------------------------------------------

  bool get suggestionsEnabled {
    return prefs.getBool(
          "suggestions",
        ) ??
        true;
  }

  Future<void> setSuggestionsEnabled(
    bool value,
  ) async {
    await prefs.setBool(
      "suggestions",
      value,
    );
  }

  // ------------------------------------------------------------
  // Smart Backspace
  // ------------------------------------------------------------

  bool get smartBackspace {
    return prefs.getBool(
          "smart_backspace",
        ) ??
        true;
  }

  Future<void> setSmartBackspace(
    bool value,
  ) async {
    await prefs.setBool(
      "smart_backspace",
      value,
    );
  }

  // ------------------------------------------------------------
  // Auto Correction
  // ------------------------------------------------------------

  bool get autoCorrect {
    return prefs.getBool(
          "auto_correct",
        ) ??
        true;
  }

  Future<void> setAutoCorrect(
    bool value,
  ) async {
    await prefs.setBool(
      "auto_correct",
      value,
    );
  }

  // ------------------------------------------------------------
  // Theme Mode
  // ------------------------------------------------------------

  String get themeMode {
    return prefs.getString(
          "theme_mode",
        ) ??
        "system";
  }

  Future<void> setThemeMode(
    String value,
  ) async {
    await prefs.setString(
      "theme_mode",
      value,
    );
  }
}
