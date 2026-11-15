import 'package:binpal/features/photo/recycling_marks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads each mark as a word of its own', () {
    expect(findRecyclingMarks('プラ'), {RecyclingMark.plastic});
    expect(findRecyclingMarks('1\nPET'), {RecyclingMark.pet});
    expect(findRecyclingMarks('1PET'), {RecyclingMark.pet});
    expect(findRecyclingMarks('アルミ'), {RecyclingMark.aluminium});
    expect(findRecyclingMarks('スチール缶'), {RecyclingMark.steel});
    expect(findRecyclingMarks('紙'), {RecyclingMark.paper});
  });

  test('folds half-width, full-width and hiragana', () {
    expect(findRecyclingMarks('ﾌﾟﾗ'), {RecyclingMark.plastic});
    expect(findRecyclingMarks('ＰＥＴ'), {RecyclingMark.pet});
    expect(findRecyclingMarks('あるみ'), {RecyclingMark.aluminium});
  });

  test('finds several marks on one package', () {
    expect(findRecyclingMarks('ボトル\nPET\nキャップ・ラベル プラ'), {
      RecyclingMark.pet,
      RecyclingMark.plastic,
    });
    expect(findRecyclingMarks('[プラ]'), {RecyclingMark.plastic});
  });

  test('words that only contain a mark are not marks', () {
    expect(findRecyclingMarks('材質: プラスチック'), isEmpty);
    expect(findRecyclingMarks('和紙'), isEmpty);
    expect(findRecyclingMarks('紙パック'), isEmpty);
    expect(findRecyclingMarks('PETAL'), isEmpty);
    expect(findRecyclingMarks('アルミホイル'), isEmpty);
  });

  test('spots spray and aerosol cans', () {
    expect(mentionsSpray('ヘアスプレー'), isTrue);
    expect(mentionsSpray('エアゾール製品'), isTrue);
    expect(mentionsSpray('Hair SPRAY'), isTrue);
    expect(mentionsSpray('スチール'), isFalse);
  });
}
