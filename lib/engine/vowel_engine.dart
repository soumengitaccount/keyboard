import 'bangla_characters.dart';

class VowelEngine {
  String apply(
    String consonant,
    String vowel,
  ) {
    final sign = BanglaCharacters.vowels[vowel];

    if (sign == null) {
      return consonant;
    }

    return consonant + sign;
  }

  bool isVowel(
    String input,
  ) {
    return BanglaCharacters.vowels.containsKey(
      input,
    );
  }

  bool isConsonant(
    String input,
  ) {
    return BanglaCharacters.consonants.containsKey(
      input,
    );
  }

  String getConsonant(
    String input,
  ) {
    return BanglaCharacters.consonants[input] ?? input;
  }
}
