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

  test('context rules select independent vowels, kar, and escaped kar', () {
    final transliterator = Transliterator();

    expect(transliterator.convert('a'), 'আ');
    expect(transliterator.convert('ka'), 'কা');
    expect(transliterator.convert('o'), 'অ');
    expect(transliterator.convert('ko'), 'ক');
    expect(transliterator.convert('a`'), 'া');
    expect(transliterator.convert('kOI'), 'কৈ');
    expect(transliterator.convert('kOU'), 'কৌ');
  });

  test('context rules form reph, r-fola, and ordered jukto letters', () {
    final transliterator = Transliterator();

    expect(transliterator.convert('rrk'), 'র্ক');
    expect(transliterator.convert('kr'), 'ক্র');
    expect(transliterator.convert('krri'), 'কৃ');
    expect(transliterator.convert('kkh'), 'ক্ষ');
    expect(transliterator.convert('kShm'), 'ক্ষ্ম');
    expect(transliterator.convert('NgkSh'), 'ঙ্ক্ষ');
    expect(transliterator.convert('bhl'), 'ভ্ল');
  });
}
