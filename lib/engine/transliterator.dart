import 'input_buffer.dart';
// import 'phonetic_rules.dart';
import 'phonetic_parser.dart';

class Transliterator {
  final InputBuffer _buffer = InputBuffer();
  String get currentText => _buffer.text;

  /// Add English key input
  String addCharacter(
    String character,
  ) {
    _buffer.add(character);

    return convert(
      _buffer.text,
    );
  }

  /// Remove last typed character
  String backspace() {
    // Keep the source phonetic sequence in the buffer. Storing the rendered
    // Bengali text here makes the next key impossible for the parser to
    // understand (for example: k, backspace, k).
    _buffer.removeLast();
    return convert(_buffer.text);
  }

  /// Clear current input
  void clear() {
    _buffer.clear();
  }

  /// Main conversion engine
  // String convert(
  //   String input,
  // ) {

  //   if (input.isEmpty) {

  //     return "";

  //   }

  //   String result =
  //       input.toLowerCase();

  //   /*
  //      Longest matching rules first.

  //      Example:

  //      "kh" must match before "k"

  //      "chh" before "ch"

  //   */

  //   final sortedRules =
  //       phoneticRules.keys.toList()
  //         ..sort(
  //           (a,b)=>
  //               b.length.compareTo(
  //                 a.length,
  //               ),
  //         );

  //   for(final rule in sortedRules){

  //     result =
  //         result.replaceAll(
  //           rule,
  //           phoneticRules[rule]!,
  //         );

  //   }

  //   return result;

  // }
  final PhoneticParser _parser = PhoneticParser();

  String convert(String input) => _parser.parse(input);
}
