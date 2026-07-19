import 'package:characters/characters.dart';

class BackspaceEngine {
  static const String hasanta = "্";

  static const List<String> vowelSigns = [
    "া",
    "ি",
    "ী",
    "ু",
    "ূ",
    "ৃ",
    "ে",
    "ৈ",
    "ো",
    "ৌ",
  ];

  String removeLast(
    String text,
  ) {
    if (text.isEmpty) {
      return "";
    }

    final chars = text.characters.toList();

    final last = chars.last;

    // Remove vowel sign first

    if (vowelSigns.contains(last)) {
      chars.removeLast();

      return chars.join();
    }

    // Remove hasanta + previous consonant

    if (last == hasanta) {
      chars.removeLast();

      if (chars.isNotEmpty) {
        chars.removeLast();
      }

      return chars.join();
    }

    // Normal unicode character removal

    chars.removeLast();

    return chars.join();
  }
}
