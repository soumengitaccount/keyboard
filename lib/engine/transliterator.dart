import 'input_buffer.dart';
// import 'phonetic_rules.dart';
import 'phonetic_parser.dart';
import 'backspace_engine.dart';

class Transliterator {
  final InputBuffer _buffer = InputBuffer();
  final BackspaceEngine _backspace = BackspaceEngine();

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
    final result = _backspace.removeLast(
      convert(
        _buffer.text,
      ),
    );

    _buffer.clear();

    _buffer.add(result);

    return result;
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
