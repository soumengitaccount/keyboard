import 'package:flutter/foundation.dart';

import '../engine/candidate_engine.dart';
import '../engine/transliterator.dart';
import 'native_bridge.dart';
import 'preferences.dart';
import '../engine/autocorrect_engine.dart';

class KeyboardService extends ChangeNotifier {
  KeyboardService._();

  static final KeyboardService instance = KeyboardService._();

  final Transliterator _translator = Transliterator();

  final CandidateEngine _candidateEngine = CandidateEngine();
  final AutoCorrectEngine _autoCorrect = AutoCorrectEngine();

  bool _enabled = true;

  bool get enabled => _enabled;

  List<String> _candidates = [];

  List<String> get candidates => _candidates;

  String _preview = "";

  String get preview => _preview;

  String get phoneticInput => _translator.currentText;

  // ------------------------------------------------------------
  // Initialize service
  // ------------------------------------------------------------

  Future<void> initialize() async {
    _enabled = PreferencesService.instance.keyboardEnabled &&
        NativeBridge.instance.supportsGlobalKeyboard;

    if (_enabled) {
      await NativeBridge.instance.enableKeyboard();
    }
  }

  // ------------------------------------------------------------
  // Enable / Disable keyboard
  // ------------------------------------------------------------

  Future<void> setEnabled(
    bool value,
  ) async {
    _enabled = value && NativeBridge.instance.supportsGlobalKeyboard;

    await PreferencesService.instance.setKeyboardEnabled(value);

    if (_enabled) {
      await NativeBridge.instance.enableKeyboard();
    } else {
      await NativeBridge.instance.disableKeyboard();
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // Receive key input
  // ------------------------------------------------------------

  Future<void> processKey(
    String key,
  ) async {
    if (!_enabled || key.isEmpty) {
      return;
    }

    _preview = _translator.addCharacter(
      key,
    );

    _candidates = _candidateEngine.search(
      _preview,
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // Commit current text
  // ------------------------------------------------------------

  Future<void> commit() async {
    if (_preview.isEmpty) {
      return;
    }

    final corrected = _autoCorrect.correct(phoneticInput);
    final finalText = corrected == phoneticInput ? _preview : corrected;

    await NativeBridge.instance.sendText(
      finalText,
    );
    // await NativeBridge.instance
    //     .sendText(
    //       _preview,
    //     );

    clear();
  }

  // ------------------------------------------------------------
  // Backspace handling
  // ------------------------------------------------------------

  /// Returns true when a character was removed from the in-memory
  /// composition. Callers should forward Backspace to the target app when it
  /// returns false.
  bool backspace() {
    if (_preview.isEmpty) return false;
    _preview = _translator.backspace();

    _candidates = _candidateEngine.search(
      _preview,
    );

    notifyListeners();
    return true;
  }

  // ------------------------------------------------------------
  // Clear buffer
  // ------------------------------------------------------------

  void clear() {
    _translator.clear();

    _preview = "";

    _candidates = [];

    notifyListeners();
  }

  // ------------------------------------------------------------
  // Select suggestion
  // ------------------------------------------------------------

  Future<void> selectCandidate(
    String word,
  ) async {
    await NativeBridge.instance.sendText(
      word,
    );

    clear();
  }
}
