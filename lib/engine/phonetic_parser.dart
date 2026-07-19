import 'vowel_engine.dart';
import 'conjunct_engine.dart';

class PhoneticParser {
  final VowelEngine _vowelEngine = VowelEngine();
  final ConjunctEngine _conjunct = ConjunctEngine();

  String parse(
    String input,
  ) {
    if (input.isEmpty) {
      return "";
    }

    String output = "";

    int index = 0;

    while (index < input.length) {
      String current = input[index];

      if (index + 1 < input.length) {
        final first = input[index];

        final second = input[index + 1];

        if (_vowelEngine.isConsonant(first) &&
            _vowelEngine.isConsonant(second)) {
          output += _conjunct.join(
            [first, second],
          );

          index += 2;

          continue;
        }
      }
      // check consonant

      if (_vowelEngine.isConsonant(
        current,
      )) {
        final consonant = _vowelEngine.getConsonant(
          current,
        );

        // look ahead vowel

        if (index + 1 < input.length) {
          String next = input[index + 1];

          if (_vowelEngine.isVowel(
            next,
          )) {
            output += _vowelEngine.apply(
              consonant,
              next,
            );

            index += 2;

            continue;
          }
        }

        output += consonant;
      } else {
        output += current;
      }

      index++;
    }

    return output;
  }
}
