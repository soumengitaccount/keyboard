import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../widgets/candidate_popup.dart';

class CandidateWindowService {
  CandidateWindowService._();

  static final CandidateWindowService instance = CandidateWindowService._();

  bool _visible = false;

  bool get visible => _visible;

  List<String> _candidates = [];

  List<String> get candidates => _candidates;

  Future<void> initialize() async {
    await windowManager.ensureInitialized();
  }

  Future<void> show(
    List<String> words,
  ) async {
    if (words.isEmpty) {
      await hide();

      return;
    }

    _candidates = words;

    _visible = true;

    await windowManager.show();

    await windowManager.setAlwaysOnTop(
      true,
    );
  }

  Future<void> hide() async {
    _visible = false;

    _candidates = [];

    await windowManager.hide();
  }

  Future<void> select(
    String word,
  ) async {
    // selection callback
    debugPrint(
      "Selected: $word",
    );

    await hide();
  }

  Widget buildWidget() {
    return CandidatePopup(
      candidates: _candidates,
      onSelected: (word) {
        select(word);
      },
    );
  }
}
