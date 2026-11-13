import 'dart:math' as math;
import 'dart:typed_data';

/// Metres per degree of latitude; longitude is scaled by cos(latitude).
const _metresPerDegree = 111320.0;

/// One area found for a position.
class AreaMatch {
  const AreaMatch({
    required this.id,
    required this.name,
    required this.distanceMetres,
  });

  /// The bundle's area id: ward or municipality code, `-`, e-Stat `S_AREA`.
  final String id;

  /// The area's Japanese name as e-Stat gives it.
  final String name;

  /// For the containing area, how far the position is from its edge; for a
  /// nearby one, how far its edge is from the position.
  final double distanceMetres;

  /// The 5-digit ward or municipality code at the start of [id].
  String get municipalityCode => id.split('-').first;

  @override
  String toString() => '$id $name (${distanceMetres.toStringAsFixed(1)} m)';
}

/// What a lookup found: the area containing the position, if any, and the
/// other areas whose edge is within the search distance, nearest first.
class AreaLookup {
  const AreaLookup({required this.inside, required this.nearby});

  final AreaMatch? inside;
  final List<AreaMatch> nearby;

  /// [inside] then [nearby]: every area the user might mean.
  List<AreaMatch> get candidates => [?inside, ...nearby];
}

class _Area {
  _Area(
    this.id,
    this.name,
    this.rings,
    this.west,
    this.south,
    this.east,
    this.north,
  );

  final String id;
  final String name;

  /// Each ring as x0, y0, x1, y1, … in degrees (longitude, latitude).
  final List<Float64List> rings;
  final double west, south, east, north;
}

/// A boundary package (`data/schema/boundaries.v1.schema.json`), decoded for
/// lookups. The same arithmetic as `data/scripts/locate.py`.
///
/// Decoding a prefecture takes a few hundred milliseconds, so it is done
/// off the UI thread (see `BoundaryStore.lookup`).
class BoundaryPackage {
  BoundaryPackage._(
    this.prefectureCode,
    this.municipalities,
    this.bbox,
    this._areas,
  );

  factory BoundaryPackage.fromJson(Map<String, dynamic> json) {
    final topology = json['topology'] as Map<String, dynamic>;
    final transform = topology['transform'] as Map<String, dynamic>;
    final scale = (transform['scale'] as List<dynamic>).cast<num>();
    final translate = (transform['translate'] as List<dynamic>).cast<num>();
    final sx = scale[0].toDouble(), sy = scale[1].toDouble();
    final tx = translate[0].toDouble(), ty = translate[1].toDouble();

    // Each arc is delta-encoded integer steps.
    final arcs = <Float64List>[
      for (final arc in topology['arcs'] as List<dynamic>)
        () {
          final steps = arc as List<dynamic>;
          final points = Float64List(steps.length * 2);
          var x = 0, y = 0;
          for (var i = 0; i < steps.length; i++) {
            final step = steps[i] as List<dynamic>;
            x += step[0] as int;
            y += step[1] as int;
            points[i * 2] = x * sx + tx;
            points[i * 2 + 1] = y * sy + ty;
          }
          return points;
        }(),
    ];

    Float64List ring(List<dynamic> indexes) {
      final out = <double>[];
      for (final raw in indexes) {
        final i = raw as int;
        // A negative index means the arc ~i, walked backwards.
        final arc = arcs[i >= 0 ? i : ~i];
        final n = arc.length ~/ 2;
        for (var k = 0; k < n; k++) {
          // Consecutive arcs share their joining point; keep it once.
          if (out.isNotEmpty && k == 0) continue;
          final j = i >= 0 ? k : n - 1 - k;
          out
            ..add(arc[j * 2])
            ..add(arc[j * 2 + 1]);
        }
      }
      return Float64List.fromList(out);
    }

    final areas = <_Area>[];
    final objects = topology['objects'] as Map<String, dynamic>;
    final geometries =
        (objects['areas'] as Map<String, dynamic>)['geometries']
            as List<dynamic>;
    for (final raw in geometries) {
      final geometry = raw as Map<String, dynamic>;
      final polygons = geometry['type'] == 'MultiPolygon'
          ? geometry['arcs'] as List<dynamic>
          : [geometry['arcs']];
      final rings = [
        for (final polygon in polygons)
          for (final r in polygon as List<dynamic>) ring(r as List<dynamic>),
      ];
      var w = double.infinity, s = double.infinity;
      var e = double.negativeInfinity, n = double.negativeInfinity;
      for (final r in rings) {
        for (var k = 0; k < r.length; k += 2) {
          w = math.min(w, r[k]);
          e = math.max(e, r[k]);
          s = math.min(s, r[k + 1]);
          n = math.max(n, r[k + 1]);
        }
      }
      areas.add(
        _Area(
          geometry['id'] as String,
          (geometry['properties'] as Map<String, dynamic>)['name'] as String,
          rings,
          w,
          s,
          e,
          n,
        ),
      );
    }
    return BoundaryPackage._(
      json['prefecture_code'] as String,
      {
        for (final MapEntry(:key, :value)
            in (json['municipalities'] as Map<String, dynamic>).entries)
          key: (value as Map<String, dynamic>)['ja'] as String,
      },
      (json['bbox'] as List<dynamic>)
          .cast<num>()
          .map((v) => v.toDouble())
          .toList(),
      areas,
    );
  }

  final String prefectureCode;

  /// Japanese names of the package's municipalities and wards, by code.
  final Map<String, String> municipalities;

  /// West, south, east, north.
  final List<double> bbox;
  final List<_Area> _areas;

  int get areaCount => _areas.length;

  bool covers(double lat, double lon) =>
      bbox[0] <= lon && lon <= bbox[2] && bbox[1] <= lat && lat <= bbox[3];

  /// The area containing ([lat], [lon]) and the others within [near] metres.
  AreaLookup locate(double lat, double lon, {double near = 50}) {
    final kx = _metresPerDegree * math.cos(lat * math.pi / 180);
    final padX = near / kx, padY = near / _metresPerDegree;
    AreaMatch? inside;
    final nearby = <AreaMatch>[];
    for (final area in _areas) {
      if (lon < area.west - padX ||
          lon > area.east + padX ||
          lat < area.south - padY ||
          lat > area.north + padY) {
        continue;
      }
      final distance = _borderDistance(area.rings, lon, lat, kx);
      if (inside == null && _contains(area.rings, lon, lat)) {
        inside = AreaMatch(
          id: area.id,
          name: area.name,
          distanceMetres: distance,
        );
      } else if (distance <= near) {
        nearby.add(
          AreaMatch(id: area.id, name: area.name, distanceMetres: distance),
        );
      }
    }
    nearby.sort((a, b) => a.distanceMetres.compareTo(b.distanceMetres));
    return AreaLookup(inside: inside, nearby: nearby);
  }
}

/// Even-odd rule over every ring, so holes and multi-part areas need no
/// special case.
bool _contains(List<Float64List> rings, double x, double y) {
  var inside = false;
  for (final r in rings) {
    var x1 = r[r.length - 2], y1 = r[r.length - 1];
    for (var k = 0; k < r.length; k += 2) {
      final x2 = r[k], y2 = r[k + 1];
      if ((y1 > y) != (y2 > y) && x < (x2 - x1) * (y - y1) / (y2 - y1) + x1) {
        inside = !inside;
      }
      x1 = x2;
      y1 = y2;
    }
  }
  return inside;
}

/// Metres from the point to the nearest edge.
double _borderDistance(List<Float64List> rings, double x, double y, double kx) {
  var best = double.infinity;
  for (final r in rings) {
    var ax = (r[r.length - 2] - x) * kx;
    var ay = (r[r.length - 1] - y) * _metresPerDegree;
    for (var k = 0; k < r.length; k += 2) {
      final bx = (r[k] - x) * kx, by = (r[k + 1] - y) * _metresPerDegree;
      final dx = bx - ax, dy = by - ay;
      final length = dx * dx + dy * dy;
      final t = length == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / length).clamp(0.0, 1.0);
      final px = ax + t * dx, py = ay + t * dy;
      best = math.min(best, math.sqrt(px * px + py * py));
      ax = bx;
      ay = by;
    }
  }
  return best;
}
