import 'dart:convert';
import 'dart:io';

import 'package:binpal/area/boundary_package.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same known addresses the data pipeline's tests check against
/// `locate.py` (data/tests/test_boundaries.py), read from that file so both
/// stay on one list: (address, lat, lon, area id, area name).
List<(String, double, double, String, String)> addresses() {
  final source = File('../data/tests/test_boundaries.py').readAsStringSync();
  final tuple = RegExp(
    r'\("([^"]+)", ([\d.]+), ([\d.]+), (?:"[^"]+", )?"([^"]+)", "(\d{5}-\d{6})"\)',
  );
  return [
    for (final m in tuple.allMatches(source))
      (m[1]!, double.parse(m[2]!), double.parse(m[3]!), m[5]!, m[4]!),
  ];
}

void main() {
  late BoundaryPackage kanagawa;

  setUpAll(() {
    final file = File('../data/boundaries/14.json');
    final watch = Stopwatch()..start();
    kanagawa = BoundaryPackage.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
    // ignore: avoid_print
    print(
      'decoded ${kanagawa.areaCount} areas in ${watch.elapsedMilliseconds} ms',
    );
  });

  test('the package decodes', () {
    expect(kanagawa.prefectureCode, '14');
    expect(kanagawa.areaCount, 5090);
    expect(kanagawa.municipalities['14117'], '横浜市青葉区');
  });

  final known = addresses();

  test('every known address from the data tests is here', () {
    expect(known.length, 67); // 22 across Kanagawa + 45 in Aoba-ku
  });

  for (final (address, lat, lon, id, name) in known) {
    test('$address is in $name', () {
      final found = kanagawa.locate(lat, lon).inside;
      expect(found?.id, id);
      expect(found?.name, name);
    });
  }

  test('near a border, the neighbour is offered too', () {
    // あざみ野二丁目1 is 48 m from あざみ野一丁目 (as locate.py finds).
    final result = kanagawa.locate(35.568253, 139.553345);
    expect(result.inside?.name, 'あざみ野二丁目');
    expect(result.inside!.distanceMetres, closeTo(47.9, 1));
    expect(result.nearby.map((m) => m.name), ['あざみ野一丁目']);
    expect(result.candidates.map((m) => m.name), ['あざみ野二丁目', 'あざみ野一丁目']);
    expect(kanagawa.locate(35.568253, 139.553345, near: 20).nearby, isEmpty);
  });

  test('outside the prefecture there is no area', () {
    const tokyoStation = (35.681236, 139.767125);
    expect(kanagawa.covers(tokyoStation.$1, tokyoStation.$2), isFalse);
    final result = kanagawa.locate(tokyoStation.$1, tokyoStation.$2);
    expect(result.inside, isNull);
    expect(result.nearby, isEmpty);
  });

  test('the ward code comes from the area id', () {
    final found = kanagawa.locate(35.543270, 139.517105).inside!;
    expect(found.municipalityCode, '14117');
  });

  test('a lookup is quick once decoded', () {
    final watch = Stopwatch()..start();
    for (final (_, lat, lon, _, _) in known) {
      kanagawa.locate(lat, lon);
    }
    final perLookup = watch.elapsedMicroseconds / known.length / 1000;
    // ignore: avoid_print
    print('lookup: ${perLookup.toStringAsFixed(2)} ms');
    expect(perLookup, lessThan(50));
  });
}
