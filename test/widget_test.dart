import 'package:flutter_test/flutter_test.dart';
import 'package:bangla_keyboard/engine/transliterator.dart';

void main() {
  test('phonetic input creates Bangla output', () {
    final transliterator = Transliterator();
    expect(transliterator.addCharacter('k'), isNotEmpty);
  });
}
