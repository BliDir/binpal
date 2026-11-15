import '../../data/normalize.dart';

/// The Japanese recycling marks (識別マーク) printed on packaging.
enum RecyclingMark {
  /// プラ: plastic packaging.
  plastic,

  /// PET (with a 1 in the triangle): PET bottles.
  pet,

  /// アルミ: aluminium cans.
  aluminium,

  /// スチール: steel cans.
  steel,

  /// 紙: paper packaging.
  paper,
}

/// The marks found in [text] recognised on a photo.
///
/// A mark is a word of its own on the package, so a line counts only when
/// one of its space-separated words is exactly the mark (プラ, PET, アルミ,
/// スチール, 紙, or アルミ缶 and スチール缶). プラスチック in an ingredients list
/// or 紙 inside 和紙 is not a mark. Text is folded with [normalizeForSearch],
/// so カタカナ, ひらがな and full-width letters are read the same.
Set<RecyclingMark> findRecyclingMarks(String text) {
  final found = <RecyclingMark>{};
  for (final line in text.split('\n')) {
    for (final word in normalizeForSearch(line).split(' ')) {
      final mark = _marks[word.replaceAll(_punctuation, '')];
      if (mark != null) found.add(mark);
    }
  }
  return found;
}

/// Whether [text] says the item is a spray or aerosol can. Spray cans carry
/// the スチール or アルミ mark but go out separately, so then the metal marks
/// don't decide the category.
bool mentionsSpray(String text) {
  final folded = normalizeForSearch(text);
  return _spray.any(folded.contains);
}

/// Keys are folded like [normalizeForSearch]: katakana become hiragana.
const _marks = {
  'ぷら': RecyclingMark.plastic,
  'pet': RecyclingMark.pet,
  '1pet': RecyclingMark.pet,
  'あるみ': RecyclingMark.aluminium,
  'あるみ缶': RecyclingMark.aluminium,
  'すちーる': RecyclingMark.steel,
  'すちーる缶': RecyclingMark.steel,
  '紙': RecyclingMark.paper,
};

const _spray = ['すぷれー', 'えあぞーる', 'spray', 'aerosol', '噴射剤'];

final _punctuation = RegExp(r'[()\[\]{}「」『』【】・.,:;!?/\\|*★☆△▲▽▼◯○]');
