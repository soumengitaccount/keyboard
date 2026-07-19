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

  // ------------------------------------------------------------
  // Initialize service
  // ------------------------------------------------------------

  Future<void> initialize() async {
    _enabled = PreferencesService.instance.keyboardEnabled;

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
    _enabled = value;

    await PreferencesService.instance.setKeyboardEnabled(
      value,
    );

    if (value) {
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
    if (!_enabled) {
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

    final finalText = _autoCorrect.correct(
      _preview,
    );

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

  void backspace() {
    _preview = _translator.backspace();

    _candidates = _candidateEngine.search(
      _preview,
    );

    notifyListeners();
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
