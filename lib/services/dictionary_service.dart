import 'dart:convert';

import 'package:flutter/services.dart';

class DictionaryService {
  DictionaryService._();

  static final DictionaryService instance = DictionaryService._();

  final List<String> _words = [];

  bool _loaded = false;

  bool get isLoaded => _loaded;

  // ------------------------------------------------------------
  // Load dictionary from assets
  // ------------------------------------------------------------

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    try {
      final jsonString = await rootBundle.loadString(
        "assets/dictionary/words.json",
      );

      final List<dynamic> data = jsonDecode(jsonString);

      _words
        ..clear()
        ..addAll(
          data.map(
            (e) => e.toString(),
          ),
        );

      _loaded = true;
    } catch (e) {
      // Fallback dictionary

      _words.addAll(
        [
          "আমি",
          "আমার",
          "আমাকে",
          "বাংলা",
          "বাংলাদেশ",
          "বাংলার",
          "ভাষা",
          "ভালো",
          "কথা",
          "কম্পিউটার",
          "কীবোর্ড",
          "অভ্র",
        ],
      );

      _loaded = true;
    }
  }

  // ------------------------------------------------------------
  // Search words
  // ------------------------------------------------------------

  List<String> search(
    String query,
  ) {
    if (query.isEmpty) {
      return [];
    }

    final result = _words.where(
      (word) {
        return word.contains(
          query,
        );
      },
    ).toList();

    return result.take(10).toList();
  }

  // ------------------------------------------------------------
  // Add user word
  // ------------------------------------------------------------

  void addWord(
    String word,
  ) {
    if (!_words.contains(word)) {
      _words.add(word);
    }
  }

  // ------------------------------------------------------------
  // Remove word
  // ------------------------------------------------------------

  void removeWord(
    String word,
  ) {
    _words.remove(word);
  }

  // ------------------------------------------------------------
  // Export dictionary
  // ------------------------------------------------------------

  List<String> get allWords => List.unmodifiable(
        _words,
      );
}
