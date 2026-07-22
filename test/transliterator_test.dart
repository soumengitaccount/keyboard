import 'package:bangla_keyboard/engine/transliterator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phonetic input renders Bangla vowels and consonants', () {
    final transliterator = Transliterator();
    for (final key in 'tumi'.split('')) {
      transliterator.addCharacter(key);
    }
    expect(transliterator.convert('tumi'), 'তুমি');
  });

  test('parser forms a conjunct and retains phonetic source on backspace', () {
    final transliterator = Transliterator();
    for (final key in 'kri'.split('')) {
      transliterator.addCharacter(key);
    }
    expect(transliterator.convert('kri'), 'ক্রি');
    transliterator.backspace();
    expect(transliterator.currentText, 'kr');
    expect(transliterator.convert(transliterator.currentText), 'ক্র');
  });
}
