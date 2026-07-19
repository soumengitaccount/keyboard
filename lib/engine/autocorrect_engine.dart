class AutoCorrectEngine {
  final Map<String, String> _corrections = {
    // Common English typing mistakes

    "valo": "ভালো",

    "valobasha": "ভালোবাসা",

    "bhalo": "ভালো",

    "bangla": "বাংলা",

    "bd": "বাংলাদেশ",

    "kibord": "কীবোর্ড",

    "komputer": "কম্পিউটার",

    "bhasa": "ভাষা",

    "manus": "মানুষ",
  };

  String correct(
    String input,
  ) {
    final lower = input.toLowerCase();

    return _corrections[lower] ?? input;
  }

  void addCorrection(
    String wrong,
    String correctWord,
  ) {
    _corrections[wrong] = correctWord;
  }

  void removeCorrection(
    String word,
  ) {
    _corrections.remove(
      word,
    );
  }

  Map<String, String> get corrections => Map.unmodifiable(
        _corrections,
      );
}
