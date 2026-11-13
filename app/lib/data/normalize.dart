/// Folds text so that the ways people type the same word compare equal:
/// full-width and half-width letters and digits, half-width katakana,
/// katakana and hiragana, and upper and lower case.
///
///     normalizeForSearch('ＵＭＢＲＥＬＬＡ') == 'umbrella'
///     normalizeForSearch('カサ') == normalizeForSearch('ｶｻ') == 'かさ'
///
/// Kanji are left alone: 傘 matches かさ only through the item's reading or
/// aliases. Runs of whitespace become one space.
String normalizeForSearch(String text) {
  final out = StringBuffer();
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    var c = runes[i];

    // Half-width katakana, with a following voiced or semi-voiced mark merged.
    if (c >= 0xFF66 && c <= 0xFF9D) {
      c = _halfWidthKana[c - 0xFF66];
      final next = i + 1 < runes.length ? runes[i + 1] : 0;
      if (next == 0xFF9E && _voiced.containsKey(c)) {
        c = _voiced[c]!;
        i++;
      } else if (next == 0xFF9F && _semiVoiced.containsKey(c)) {
        c = _semiVoiced[c]!;
        i++;
      }
    } else if (c >= 0xFF01 && c <= 0xFF5E) {
      c -= 0xFEE0; // full-width ASCII
    } else if (c == 0x3000) {
      c = 0x20; // ideographic space
    } else if (c == 0x301C) {
      c = 0x7E; // wave dash
    }

    // Katakana to hiragana (ァ..ヶ). ー, ・ and ヽヾ stay as they are.
    if (c >= 0x30A1 && c <= 0x30F6) c -= 0x60;

    // Combining voiced marks after hiragana (か + ゛).
    if ((c == 0x3099 || c == 0x309B) && out.isNotEmpty) {
      final merged = _voiced[_last(out) + 0x60];
      if (merged != null) {
        _replaceLast(out, merged - 0x60);
        continue;
      }
    }
    if ((c == 0x309A || c == 0x309C) && out.isNotEmpty) {
      final merged = _semiVoiced[_last(out) + 0x60];
      if (merged != null) {
        _replaceLast(out, merged - 0x60);
        continue;
      }
    }
    out.writeCharCode(c);
  }
  return out.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

int _last(StringBuffer b) => b.toString().runes.last;

void _replaceLast(StringBuffer b, int c) {
  final runes = b.toString().runes.toList()..removeLast();
  b
    ..clear()
    ..write(String.fromCharCodes(runes))
    ..writeCharCode(c);
}

/// Full-width katakana for U+FF66 (ｦ) to U+FF9D (ﾝ), in order.
const _halfWidthKana = [
  0x30F2, // ｦ
  0x30A1, 0x30A3, 0x30A5, 0x30A7, 0x30A9, // ｧｨｩｪｫ
  0x30E3, 0x30E5, 0x30E7, 0x30C3, // ｬｭｮｯ
  0x30FC, // ｰ
  0x30A2, 0x30A4, 0x30A6, 0x30A8, 0x30AA, // ｱｲｳｴｵ
  0x30AB, 0x30AD, 0x30AF, 0x30B1, 0x30B3, // ｶｷｸｹｺ
  0x30B5, 0x30B7, 0x30B9, 0x30BB, 0x30BD, // ｻｼｽｾｿ
  0x30BF, 0x30C1, 0x30C4, 0x30C6, 0x30C8, // ﾀﾁﾂﾃﾄ
  0x30CA, 0x30CB, 0x30CC, 0x30CD, 0x30CE, // ﾅﾆﾇﾈﾉ
  0x30CF, 0x30D2, 0x30D5, 0x30D8, 0x30DB, // ﾊﾋﾌﾍﾎ
  0x30DE, 0x30DF, 0x30E0, 0x30E1, 0x30E2, // ﾏﾐﾑﾒﾓ
  0x30E4, 0x30E6, 0x30E8, // ﾔﾕﾖ
  0x30E9, 0x30EA, 0x30EB, 0x30EC, 0x30ED, // ﾗﾘﾙﾚﾛ
  0x30EF, 0x30F3, // ﾜﾝ
];

/// Katakana with the voiced mark added (カ → ガ, ウ → ヴ).
const _voiced = {
  0x30AB: 0x30AC,
  0x30AD: 0x30AE,
  0x30AF: 0x30B0,
  0x30B1: 0x30B2,
  0x30B3: 0x30B4,
  0x30B5: 0x30B6,
  0x30B7: 0x30B8,
  0x30B9: 0x30BA,
  0x30BB: 0x30BC,
  0x30BD: 0x30BE,
  0x30BF: 0x30C0,
  0x30C1: 0x30C2,
  0x30C4: 0x30C5,
  0x30C6: 0x30C7,
  0x30C8: 0x30C9,
  0x30CF: 0x30D0,
  0x30D2: 0x30D3,
  0x30D5: 0x30D6,
  0x30D8: 0x30D9,
  0x30DB: 0x30DC,
  0x30A6: 0x30F4,
};

/// Katakana with the semi-voiced mark added (ハ → パ).
const _semiVoiced = {
  0x30CF: 0x30D1,
  0x30D2: 0x30D4,
  0x30D5: 0x30D7,
  0x30D8: 0x30DA,
  0x30DB: 0x30DD,
};
