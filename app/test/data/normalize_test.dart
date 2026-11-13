import 'package:binpal/data/normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('katakana, half-width katakana and hiragana compare equal', () {
    expect(normalizeForSearch('カサ'), 'かさ');
    expect(normalizeForSearch('ｶｻ'), 'かさ');
    expect(normalizeForSearch('かさ'), 'かさ');
  });

  test('half-width voiced and semi-voiced marks merge', () {
    expect(normalizeForSearch('ﾊﾞｯﾃﾘｰ'), 'ばってりー');
    expect(normalizeForSearch('ﾍﾟｯﾄﾎﾞﾄﾙ'), 'ぺっとぼとる');
    expect(normalizeForSearch('ｳﾞ'), 'ゔ');
  });

  test('combining voiced marks merge', () {
    expect(normalizeForSearch('がみ'), 'がみ');
    expect(normalizeForSearch('ぱん'), 'ぱん');
  });

  test('full-width letters, digits and spaces become ASCII, lower case', () {
    expect(normalizeForSearch('ＵＭＢＲＥＬＬＡ'), 'umbrella');
    expect(normalizeForSearch('ＰＥＴボトル'), 'petぼとる');
    expect(normalizeForSearch('５０ｃｍ'), '50cm');
    expect(normalizeForSearch('  Clothes　 IRON  '), 'clothes iron');
    expect(normalizeForSearch('（金属製）'), '(金属製)');
  });

  test('kanji and the long vowel mark are kept', () {
    expect(normalizeForSearch('傘'), '傘');
    expect(normalizeForSearch('ボール'), 'ぼーる');
  });
}
