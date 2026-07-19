import 'bangla_characters.dart';

class ConjunctEngine {
  static const String hasanta = "্";

  String join(
    List<String> consonants,
  ) {
    if (consonants.isEmpty) {
      return "";
    }

    if (consonants.length == 1) {
      return consonants.first;
    }

    String result = "";

    for (int i = 0; i < consonants.length; i++) {
      final char = BanglaCharacters.consonants[consonants[i]] ?? consonants[i];

      result += char;

      if (i < consonants.length - 1) {
        result += hasanta;
      }
    }

    return result;
  }

  bool isCluster(
    String input,
  ) {
    int count = 0;

    for (final char in input.split("")) {
      if (BanglaCharacters.consonants.containsKey(
        char,
      )) {
        count++;
      }
    }

    return count > 1;
  }
}
