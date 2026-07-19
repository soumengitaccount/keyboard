import 'dart:collection';

class CandidateEngine {
  final List<String> _dictionary = [
    "আমি",
    "আমার",
    "আমাকে",
    "বাংলা",
    "বাংলাদেশ",
    "বাংলার",
    "বাংলাদেশি",
    "ভাষা",
    "ভালো",
    "ভালবাসা",
    "কথা",
    "কম্পিউটার",
    "কীবোর্ড",
    "অভ্র",
  ];

  /// Find possible words
  List<String> search(
    String input,
  ) {
    if (input.isEmpty) {
      return [];
    }

    final query = input.toLowerCase();

    final matches = _dictionary.where(
      (word) {
        return _containsPhonetic(
          word,
          query,
        );
      },
    ).toList();

    return matches.take(10).toList();
  }

  /// Simple phonetic matching
  bool _containsPhonetic(
    String word,
    String query,
  ) {
    final normalized = word.toLowerCase();

    return normalized.contains(
      query,
    );
  }

  /// Add custom word
  void addWord(
    String word,
  ) {
    if (!_dictionary.contains(word)) {
      _dictionary.add(word);
    }
  }

  /// Remove word
  void removeWord(
    String word,
  ) {
    _dictionary.remove(word);
  }

  /// Get all words
  UnmodifiableListView<String> get words => UnmodifiableListView(
        _dictionary,
      );
}
