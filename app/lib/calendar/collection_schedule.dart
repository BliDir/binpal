/// Answers "what goes out on which day" for one area, from a bundle's
/// calendars and exception dates. Pure Dart, no database or Flutter.
///
/// The rules are the ones in `data/schema/README.md` ("Collection days"):
/// a category is collected in an area on a date when
///
/// 1. a calendar lists both the category and the area, the date is inside the
///    calendar's validity range, and its pattern matches the date, and no
///    `no_collection` exception matches; or
/// 2. an `extra_collection` exception matches.
library;

/// A calendar date in Japan, with no time of day or time zone.
class JapanDate implements Comparable<JapanDate> {
  JapanDate(int year, int month, int day)
    : _utc = DateTime.utc(year, month, day);

  JapanDate._(this._utc);

  /// `YYYY-MM-DD`, as bundles write dates.
  factory JapanDate.parse(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) throw FormatException('not a date', text);
    final date = JapanDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
    if (date.toString() != text) throw FormatException('not a date', text);
    return date;
  }

  /// The date in Japan at [moment] (Japan has no daylight saving time).
  factory JapanDate.at(DateTime moment) {
    final japan = moment.toUtc().add(const Duration(hours: 9));
    return JapanDate(japan.year, japan.month, japan.day);
  }

  factory JapanDate.today() => JapanDate.at(DateTime.now());

  final DateTime _utc;

  int get year => _utc.year;
  int get month => _utc.month;
  int get day => _utc.day;

  /// 1 = Monday … 7 = Sunday.
  int get weekday => _utc.weekday;

  /// Which occurrence of its weekday this is in the month: days 1–7 are the
  /// 1st, 8–14 the 2nd, and so on up to the 5th.
  int get weekOfMonth => (day - 1) ~/ 7 + 1;

  JapanDate addDays(int days) =>
      JapanDate._(DateTime.utc(year, month, day + days));

  int daysUntil(JapanDate other) => other._utc.difference(_utc).inDays;

  /// This date at [hour]:[minute] Japan time, as an instant.
  DateTime atJapanTime(int hour, int minute) => DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
  ).subtract(const Duration(hours: 9));

  bool isBefore(JapanDate other) => compareTo(other) < 0;
  bool isAfter(JapanDate other) => compareTo(other) > 0;

  @override
  int compareTo(JapanDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) => other is JapanDate && other._utc == _utc;

  @override
  int get hashCode => _utc.hashCode;

  @override
  String toString() {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-${two(month)}-${two(day)}';
  }
}

/// Whether [date] is inside an inclusive range; no [to] means open-ended.
bool isValidOn(JapanDate date, JapanDate from, JapanDate? to) =>
    !date.isBefore(from) && (to == null || !date.isAfter(to));

/// A repeating collection pattern. Types the app does not know are kept as
/// [UnknownPattern] and never match, so a new pattern type in a bundle is
/// skipped instead of breaking the whole calendar.
sealed class CollectionPattern {
  const CollectionPattern();

  factory CollectionPattern.fromJson(Map<String, dynamic> json) {
    try {
      switch (json['type']) {
        case 'weekly':
          return WeeklyPattern({
            for (final d in json['weekdays'] as List<dynamic>)
              _weekday(d as String),
          });
        case 'monthly_nth_weekday':
          return MonthlyNthWeekdayPattern(_weekday(json['weekday'] as String), {
            for (final n in json['nth'] as List<dynamic>) n as int,
          });
      }
    } on Object {
      // A known type with unexpected contents is treated like an unknown one.
    }
    return UnknownPattern(json['type']?.toString() ?? '');
  }

  bool matches(JapanDate date);
}

/// Every week on [weekdays] (1 = Monday … 7 = Sunday).
class WeeklyPattern extends CollectionPattern {
  const WeeklyPattern(this.weekdays);

  final Set<int> weekdays;

  @override
  bool matches(JapanDate date) => weekdays.contains(date.weekday);
}

/// The [nth] occurrences of [weekday] in each month, for example the 2nd and
/// 4th Wednesday.
class MonthlyNthWeekdayPattern extends CollectionPattern {
  const MonthlyNthWeekdayPattern(this.weekday, this.nth);

  final int weekday;
  final Set<int> nth;

  @override
  bool matches(JapanDate date) =>
      date.weekday == weekday && nth.contains(date.weekOfMonth);
}

class UnknownPattern extends CollectionPattern {
  const UnknownPattern(this.type);

  final String type;

  @override
  bool matches(JapanDate date) => false;
}

const _weekdays = {
  'mon': 1,
  'tue': 2,
  'wed': 3,
  'thu': 4,
  'fri': 5,
  'sat': 6,
  'sun': 7,
};

int _weekday(String name) =>
    _weekdays[name] ?? (throw FormatException('unknown weekday', name));

/// One calendar from a bundle, already narrowed to the area being asked about.
class CalendarEntry {
  const CalendarEntry({
    required this.id,
    required this.categories,
    required this.pattern,
    required this.validFrom,
    this.validTo,
    this.putOutBy,
  });

  final String id;
  final List<String> categories;
  final CollectionPattern pattern;
  final JapanDate validFrom;
  final JapanDate? validTo;

  /// `HH:MM` local time by which items must be out, if the bundle says.
  final String? putOutBy;

  bool collectsOn(JapanDate date) =>
      isValidOn(date, validFrom, validTo) && pattern.matches(date);
}

enum ExceptionType { noCollection, extraCollection }

/// One exception date from a bundle, already narrowed to the area.
class ExceptionEntry {
  const ExceptionEntry({
    required this.date,
    required this.type,
    this.categories,
    this.noteJa,
    this.noteEn,
  });

  final JapanDate date;
  final ExceptionType type;

  /// Null means every category (allowed for [ExceptionType.noCollection]).
  final Set<String>? categories;
  final String? noteJa;
  final String? noteEn;

  bool covers(String category) =>
      categories == null || categories!.contains(category);
}

/// A category collected on a date.
class Collection {
  const Collection({
    required this.category,
    this.putOutBy,
    this.calendarId,
    this.extra = false,
  });

  final String category;
  final String? putOutBy;

  /// The calendar it comes from; null for an extra collection.
  final String? calendarId;

  /// Added by an `extra_collection` exception, not the regular pattern.
  final bool extra;

  @override
  String toString() =>
      '$category${extra ? ' (extra)' : ''}${putOutBy == null ? '' : ' by $putOutBy'}';
}

/// What happens on one date in one area.
class CollectionDay {
  const CollectionDay({
    required this.date,
    required this.collections,
    this.cancelled = const [],
    this.notes = const [],
  });

  final JapanDate date;

  /// Categories collected, in the order of the bundle's calendars.
  final List<Collection> collections;

  /// Categories the regular pattern would have collected but an exception
  /// cancelled, so the app can say "no collection today" instead of nothing.
  final List<String> cancelled;

  /// The notes of the exceptions that applied.
  final List<ExceptionEntry> notes;

  bool get isEmpty => collections.isEmpty;

  @override
  String toString() =>
      '$date: ${collections.join(', ')}'
      '${cancelled.isEmpty ? '' : ' (cancelled: ${cancelled.join(', ')})'}';
}

/// The collection schedule of one area.
class CollectionSchedule {
  CollectionSchedule({
    required this.calendars,
    required List<ExceptionEntry> exceptions,
  }) {
    for (final e in exceptions) {
      (_exceptions[e.date] ??= []).add(e);
    }
  }

  /// The area's calendars, in bundle order.
  final List<CalendarEntry> calendars;
  final _exceptions = <JapanDate, List<ExceptionEntry>>{};

  CollectionDay on(JapanDate date) {
    final exceptions = _exceptions[date] ?? const [];
    final cancels = exceptions
        .where((e) => e.type == ExceptionType.noCollection)
        .toList();
    final extras = exceptions
        .where((e) => e.type == ExceptionType.extraCollection)
        .toList();

    final collections = <Collection>[];
    final cancelled = <String>[];
    final seen = <String>{};
    for (final calendar in calendars) {
      if (!calendar.collectsOn(date)) continue;
      for (final category in calendar.categories) {
        if (!seen.add(category)) continue;
        if (cancels.any((e) => e.covers(category))) {
          cancelled.add(category);
        } else {
          collections.add(
            Collection(
              category: category,
              putOutBy: calendar.putOutBy,
              calendarId: calendar.id,
            ),
          );
        }
      }
    }
    for (final extra in extras) {
      for (final category in extra.categories ?? const <String>{}) {
        if (collections.any((c) => c.category == category)) continue;
        cancelled.remove(category);
        collections.add(
          Collection(
            category: category,
            putOutBy: _usualPutOutBy(category),
            extra: true,
          ),
        );
      }
    }
    return CollectionDay(
      date: date,
      collections: collections,
      cancelled: cancelled,
      notes: exceptions,
    );
  }

  /// Every day from [from] for [days] days, including days with nothing.
  List<CollectionDay> days(JapanDate from, int days) => [
    for (var i = 0; i < days; i++) on(from.addDays(i)),
  ];

  /// The usual put-out time of [category], for extra collections, which
  /// bundles do not give a time for.
  String? _usualPutOutBy(String category) {
    for (final c in calendars) {
      if (c.categories.contains(category) && c.putOutBy != null) {
        return c.putOutBy;
      }
    }
    return null;
  }
}
