/// Stateless, incremental-friendly phonetic renderer.
///
/// It deliberately works from the complete Latin composition on every key
/// press. That makes edits deterministic and lets [Transliterator] keep the
/// original phonetic buffer for smart Backspace.
class PhoneticParser {
  static const _hasanta = '্';

  static const Map<String, String> _consonants = {
    'kkh': 'ক্ষ',
    'ng': 'ং',
    'ngg': 'ঙ্গ',
    'kh': 'খ',
    'gh': 'ঘ',
    'chh': 'ছ',
    'ch': 'চ',
    'jh': 'ঝ',
    'th': 'থ',
    'dh': 'ধ',
    'ph': 'ফ',
    'bh': 'ভ',
    'sh': 'শ',
    'tt': 'ট',
    'dd': 'ড',
    'rr': 'ড়',
    'k': 'ক',
    'g': 'গ',
    'c': 'চ',
    'j': 'জ',
    't': 'ত',
    'd': 'দ',
    'n': 'ন',
    'p': 'প',
    'b': 'ব',
    'm': 'ম',
    'r': 'র',
    'l': 'ল',
    's': 'স',
    'h': 'হ',
    'y': 'য়',
    'w': 'ও',
    'f': 'ফ',
    'v': 'ভ',
    'z': 'য',
    'q': 'ক',
    'x': 'ক্স',
  };

  static const Map<String, _Vowel> _vowels = {
    'ou': _Vowel('ঔ', 'ৌ'),
    'oi': _Vowel('ঐ', 'ৈ'),
    'aa': _Vowel('আ', 'া'),
    'ii': _Vowel('ঈ', 'ী'),
    'uu': _Vowel('ঊ', 'ূ'),
    'a': _Vowel('আ', 'া'),
    'i': _Vowel('ই', 'ি'),
    'u': _Vowel('উ', 'ু'),
    'e': _Vowel('এ', 'ে'),
    'o': _Vowel('ও', 'ো'),
  };

  static final List<String> _rules = [..._consonants.keys, ..._vowels.keys]
    ..sort((left, right) => right.length.compareTo(left.length));

  String parse(String input) {
    final source = input.toLowerCase();
    final output = StringBuffer();
    var previousWasConsonant = false;
    var index = 0;

    while (index < source.length) {
      String? rule;
      for (final candidate in _rules) {
        if (source.startsWith(candidate, index)) {
          rule = candidate;
          break;
        }
      }
      if (rule == null) {
        output.write(input[index]);
        previousWasConsonant = false;
        index++;
        continue;
      }

      final consonant = _consonants[rule];
      if (consonant != null) {
        // Anusvara is a combining nasal mark, not the start of a conjunct.
        if (rule == 'ng') {
          output.write(consonant);
          previousWasConsonant = false;
        } else {
          if (previousWasConsonant) output.write(_hasanta);
          output.write(consonant);
          previousWasConsonant = true;
        }
      } else {
        final vowel = _vowels[rule]!;
        output.write(previousWasConsonant ? vowel.kar : vowel.letter);
        previousWasConsonant = false;
      }
      index += rule.length;
    }
    return output.toString();
  }
}

class _Vowel {
  const _Vowel(this.letter, this.kar);
  final String letter;
  final String kar;
}
