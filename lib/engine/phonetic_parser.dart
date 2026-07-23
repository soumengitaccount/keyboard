import 'dart:convert';
import 'dart:io';

import 'avro_rule_data.dart';

/// An ordered, context-aware implementation of the Avro phonetic scheme.
///
/// A pattern may use its neighbouring source characters to choose a vowel's
/// independent letter or kar, form a conjunct, or move `r` into a reph. This
/// matters for inputs such as `banglay`, `kOI`, `arrk`, and `krri`; a simple
/// longest-prefix transliterator cannot represent those contexts correctly.
class PhoneticParser {
  PhoneticParser() : _data = _AvroData.decode();

  final _AvroData _data;

  String parse(String input) {
    final source = _normalise(input);
    final output = StringBuffer();

    var index = 0;
    while (index < source.length) {
      final pattern = _data.matchAt(source, index);
      if (pattern == null) {
        output.write(source[index]);
        index++;
        continue;
      }

      final end = index + pattern.find.length;
      final replacement = _replacementFor(pattern, source, index, end);
      output.write(replacement);
      index = end;
    }
    return output.toString();
  }

  String _normalise(String input) {
    final fixed = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      final character = String.fromCharCode(codeUnit);
      fixed.write(_data.isCaseSensitive(character)
          ? character
          : character.toLowerCase());
    }
    return fixed.toString();
  }

  String _replacementFor(
    _Pattern pattern,
    String source,
    int start,
    int end,
  ) {
    for (final rule in pattern.rules) {
      if (rule.matches.every((match) => _matches(match, source, start, end))) {
        return rule.replace;
      }
    }
    return pattern.replace;
  }

  bool _matches(_ContextMatch match, String source, int start, int end) {
    final position = match.type == _MatchType.suffix ? end : start - 1;
    final negative = match.scope.startsWith('!');
    final scope = negative ? match.scope.substring(1) : match.scope;

    final bool matched;
    switch (scope) {
      case 'punctuation':
        matched = position < 0 ||
            position >= source.length ||
            _data.isPunctuation(source[position]);
      case 'vowel':
        matched = position >= 0 &&
            position < source.length &&
            _data.isVowel(source[position]);
      case 'consonant':
        matched = position >= 0 &&
            position < source.length &&
            _data.isConsonant(source[position]);
      case 'exact':
        final value = match.value;
        final exactStart =
            match.type == _MatchType.suffix ? end : start - value.length;
        final exactEnd =
            match.type == _MatchType.suffix ? end + value.length : start;
        matched = exactStart >= 0 &&
            exactEnd <= source.length &&
            source.substring(exactStart, exactEnd) == value;
      default:
        return false;
    }
    return negative ? !matched : matched;
  }
}

enum _MatchType { prefix, suffix }

class _AvroData {
  _AvroData({
    required this.patterns,
    required this.vowels,
    required this.consonants,
    required this.caseSensitive,
  });

  factory _AvroData.decode() {
    final encoded = base64Decode(avroRuleData);
    final json =
        jsonDecode(utf8.decode(gzip.decode(encoded))) as Map<String, dynamic>;
    return _AvroData(
      patterns: (json['patterns'] as List<dynamic>)
          .map((value) => _Pattern.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      vowels: json['vowel'] as String,
      consonants: json['consonant'] as String,
      caseSensitive: json['casesensitive'] as String,
    );
  }

  final List<_Pattern> patterns;
  final String vowels;
  final String consonants;
  final String caseSensitive;

  _Pattern? matchAt(String source, int index) {
    for (final pattern in patterns) {
      if (source.startsWith(pattern.find, index)) return pattern;
    }
    return null;
  }

  bool isVowel(String character) => vowels.contains(character.toLowerCase());

  bool isConsonant(String character) =>
      consonants.contains(character.toLowerCase());

  bool isPunctuation(String character) =>
      !isVowel(character) && !isConsonant(character);

  bool isCaseSensitive(String character) =>
      caseSensitive.contains(character.toLowerCase());
}

class _Pattern {
  const _Pattern({
    required this.find,
    required this.replace,
    required this.rules,
  });

  factory _Pattern.fromJson(Map<String, dynamic> json) {
    return _Pattern(
      find: json['find'] as String,
      replace: json['replace'] as String,
      rules: ((json['rules'] as List<dynamic>?) ?? const <dynamic>[])
          .map((value) => _Rule.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String find;
  final String replace;
  final List<_Rule> rules;
}

class _Rule {
  const _Rule({required this.matches, required this.replace});

  factory _Rule.fromJson(Map<String, dynamic> json) {
    return _Rule(
      matches: (json['matches'] as List<dynamic>)
          .map((value) => _ContextMatch.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      replace: json['replace'] as String,
    );
  }

  final List<_ContextMatch> matches;
  final String replace;
}

class _ContextMatch {
  const _ContextMatch({
    required this.type,
    required this.scope,
    required this.value,
  });

  factory _ContextMatch.fromJson(Map<String, dynamic> json) {
    return _ContextMatch(
      type: json['type'] == 'suffix' ? _MatchType.suffix : _MatchType.prefix,
      scope: json['scope'] as String,
      value: json['value'] as String? ?? '',
    );
  }

  final _MatchType type;
  final String scope;
  final String value;
}
