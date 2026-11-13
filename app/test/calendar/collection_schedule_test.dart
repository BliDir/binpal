import 'package:binpal/calendar/collection_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

JapanDate d(String s) => JapanDate.parse(s);

CalendarEntry weekly(
  String id,
  List<String> categories,
  List<String> days, {
  String from = '2025-04-01',
  String? to,
  String? putOutBy = '08:00',
}) => CalendarEntry(
  id: id,
  categories: categories,
  pattern: CollectionPattern.fromJson({'type': 'weekly', 'weekdays': days}),
  validFrom: d(from),
  validTo: to == null ? null : d(to),
  putOutBy: putOutBy,
);

List<String> categoriesOn(CollectionSchedule s, String date) => [
  for (final c in s.on(d(date)).collections) c.category,
];

/// Dates from [from] to [to] inclusive on which [category] is collected.
List<String> datesOf(
  CollectionSchedule s,
  String category,
  String from,
  String to,
) => [
  for (final day in s.days(d(from), d(from).daysUntil(d(to)) + 1))
    if (day.collections.any((c) => c.category == category)) '${day.date}',
];

void main() {
  group('JapanDate', () {
    test('parses and prints bundle dates', () {
      expect('${d('2026-11-13')}', '2026-11-13');
      expect(() => d('2026-02-30'), throwsFormatException);
      expect(() => d('2026-1-3'), throwsFormatException);
    });

    test('takes the date in Japan, not in the device time zone', () {
      // 23:30 UTC on 12 November is 08:30 on 13 November in Japan.
      expect(
        '${JapanDate.at(DateTime.utc(2026, 11, 12, 23, 30))}',
        '2026-11-13',
      );
      expect(
        '${JapanDate.at(DateTime.utc(2026, 11, 12, 14, 59))}',
        '2026-11-12',
      );
    });

    test('weekday and week of month', () {
      expect(d('2026-11-13').weekday, DateTime.friday);
      expect(d('2026-11-07').weekOfMonth, 1);
      expect(d('2026-11-08').weekOfMonth, 2);
      expect(d('2026-11-29').weekOfMonth, 5);
    });

    test('adds days across months and years', () {
      expect('${d('2026-12-30').addDays(3)}', '2027-01-02');
      expect('${d('2028-02-28').addDays(1)}', '2028-02-29');
      expect(d('2026-12-25').daysUntil(d('2027-01-04')), 10);
    });

    test('a time on the date in Japan, as an instant', () {
      expect(d('2026-11-13').atJapanTime(7, 0), DateTime.utc(2026, 11, 12, 22));
    });
  });

  group('patterns', () {
    test('weekly on one day', () {
      final s = CollectionSchedule(
        calendars: [
          weekly('p', ['plastic'], ['wed']),
        ],
        exceptions: const [],
      );
      expect(datesOf(s, 'plastic', '2026-11-01', '2026-11-30'), [
        '2026-11-04',
        '2026-11-11',
        '2026-11-18',
        '2026-11-25',
      ]);
    });

    test('weekly on several days, with several categories sharing them', () {
      final s = CollectionSchedule(
        calendars: [
          weekly('b', ['moyasu', 'moenai', 'spray', 'denchi'], ['tue', 'sat']),
        ],
        exceptions: const [],
      );
      expect(datesOf(s, 'moenai', '2026-11-09', '2026-11-22'), [
        '2026-11-10',
        '2026-11-14',
        '2026-11-17',
        '2026-11-21',
      ]);
      expect(categoriesOn(s, '2026-11-10'), [
        'moyasu',
        'moenai',
        'spray',
        'denchi',
      ]);
      expect(s.on(d('2026-11-10')).collections.first.putOutBy, '08:00');
      expect(s.on(d('2026-11-11')).isEmpty, isTrue);
    });

    test('2nd and 4th Wednesday of the month', () {
      final s = CollectionSchedule(
        calendars: [
          CalendarEntry(
            id: 'n',
            categories: const ['moenai'],
            pattern: CollectionPattern.fromJson({
              'type': 'monthly_nth_weekday',
              'weekday': 'wed',
              'nth': [2, 4],
            }),
            validFrom: d('2025-04-01'),
          ),
        ],
        exceptions: const [],
      );
      expect(datesOf(s, 'moenai', '2026-11-01', '2027-01-31'), [
        '2026-11-11',
        '2026-11-25',
        '2026-12-09',
        '2026-12-23',
        '2027-01-13',
        '2027-01-27',
      ]);
    });

    test('a 5th occurrence only in months that have one', () {
      final s = CollectionSchedule(
        calendars: [
          CalendarEntry(
            id: 'n',
            categories: const ['sodai'],
            pattern: CollectionPattern.fromJson({
              'type': 'monthly_nth_weekday',
              'weekday': 'sun',
              'nth': [5],
            }),
            validFrom: d('2025-04-01'),
          ),
        ],
        exceptions: const [],
      );
      // November 2026 and January 2027 have five Sundays; December has four.
      expect(datesOf(s, 'sodai', '2026-11-01', '2027-01-31'), [
        '2026-11-29',
        '2027-01-31',
      ]);
    });

    test(
      'an unknown or malformed pattern never matches but does not throw',
      () {
        expect(
          CollectionPattern.fromJson({
            'type': 'biweekly',
            'anchor': '2026-01-01',
          }),
          isA<UnknownPattern>(),
        );
        expect(
          CollectionPattern.fromJson({
            'type': 'weekly',
            'weekdays': ['moonday'],
          }),
          isA<UnknownPattern>(),
        );
        final s = CollectionSchedule(
          calendars: [
            CalendarEntry(
              id: 'x',
              categories: const ['moyasu'],
              pattern: CollectionPattern.fromJson({'type': 'biweekly'}),
              validFrom: d('2025-04-01'),
            ),
            weekly('p', ['plastic'], ['wed']),
          ],
          exceptions: const [],
        );
        expect(categoriesOn(s, '2026-11-11'), ['plastic']);
      },
    );
  });

  group('validity ranges', () {
    test('a schedule change mid-month switches over on the right day', () {
      // Plastic moves from Wednesday to Thursday from 16 November.
      final s = CollectionSchedule(
        calendars: [
          weekly('old', ['plastic'], ['wed'], to: '2026-11-15'),
          weekly('new', ['plastic'], ['thu'], from: '2026-11-16'),
        ],
        exceptions: const [],
      );
      expect(datesOf(s, 'plastic', '2026-11-01', '2026-11-30'), [
        '2026-11-04',
        '2026-11-11',
        '2026-11-19',
        '2026-11-26',
      ]);
      expect(s.on(d('2026-11-19')).collections.single.calendarId, 'new');
    });

    test('both ends of the range are inclusive', () {
      final s = CollectionSchedule(
        calendars: [
          weekly(
            'c',
            ['plastic'],
            ['wed'],
            from: '2026-11-11',
            to: '2026-11-18',
          ),
        ],
        exceptions: const [],
      );
      expect(datesOf(s, 'plastic', '2026-11-01', '2026-11-30'), [
        '2026-11-11',
        '2026-11-18',
      ]);
    });

    test('isValidOn', () {
      expect(isValidOn(d('2026-11-13'), d('2026-11-13'), null), isTrue);
      expect(isValidOn(d('2026-11-12'), d('2026-11-13'), null), isFalse);
      expect(
        isValidOn(d('2026-11-30'), d('2026-11-13'), d('2026-11-30')),
        isTrue,
      );
      expect(
        isValidOn(d('2026-12-01'), d('2026-11-13'), d('2026-11-30')),
        isFalse,
      );
    });
  });

  group('exceptions', () {
    final regular = [
      weekly('b', ['moyasu', 'moenai'], ['mon', 'fri']),
      weekly('c', ['kan-bin-pet', 'kinzoku'], ['thu']),
    ];

    test('no collection for every category', () {
      final s = CollectionSchedule(
        calendars: regular,
        exceptions: [
          ExceptionEntry(
            date: d('2027-01-01'),
            type: ExceptionType.noCollection,
            noteEn: 'No collection over the New Year holidays',
          ),
        ],
      );
      final day = s.on(d('2027-01-01'));
      expect(day.isEmpty, isTrue);
      expect(day.cancelled, ['moyasu', 'moenai']);
      expect(day.notes.single.noteEn, contains('New Year'));
      expect(categoriesOn(s, '2027-01-04'), ['moyasu', 'moenai']);
    });

    test('no collection for some categories only', () {
      final s = CollectionSchedule(
        calendars: regular,
        exceptions: [
          ExceptionEntry(
            date: d('2026-11-13'),
            type: ExceptionType.noCollection,
            categories: const {'moenai'},
          ),
        ],
      );
      expect(categoriesOn(s, '2026-11-13'), ['moyasu']);
      expect(s.on(d('2026-11-13')).cancelled, ['moenai']);
    });

    test('an extra collection on a day with none', () {
      final s = CollectionSchedule(
        calendars: regular,
        exceptions: [
          ExceptionEntry(
            date: d('2026-11-14'),
            type: ExceptionType.extraCollection,
            categories: const {'moyasu'},
          ),
        ],
      );
      final c = s.on(d('2026-11-14')).collections.single;
      expect(c.category, 'moyasu');
      expect(c.extra, isTrue);
      expect(c.putOutBy, '08:00');
    });

    test('a moved collection is one of each', () {
      final s = CollectionSchedule(
        calendars: regular,
        exceptions: [
          ExceptionEntry(
            date: d('2027-01-01'),
            type: ExceptionType.noCollection,
            categories: const {'moyasu', 'moenai'},
          ),
          ExceptionEntry(
            date: d('2027-01-02'),
            type: ExceptionType.extraCollection,
            categories: const {'moyasu', 'moenai'},
          ),
        ],
      );
      expect(categoriesOn(s, '2027-01-01'), isEmpty);
      expect(categoriesOn(s, '2027-01-02'), ['moyasu', 'moenai']);
    });

    test(
      'an extra collection of a category already collected is not doubled',
      () {
        final s = CollectionSchedule(
          calendars: regular,
          exceptions: [
            ExceptionEntry(
              date: d('2026-11-13'),
              type: ExceptionType.extraCollection,
              categories: const {'moyasu'},
            ),
          ],
        );
        expect(categoriesOn(s, '2026-11-13'), ['moyasu', 'moenai']);
        expect(s.on(d('2026-11-13')).collections.first.extra, isFalse);
      },
    );
  });

  test('the year boundary with the New Year closure', () {
    final s = CollectionSchedule(
      calendars: [
        weekly('b', ['moyasu'], ['tue', 'sat']),
        weekly('p', ['plastic'], ['wed']),
      ],
      exceptions: [
        for (final date in [
          '2026-12-31',
          '2027-01-01',
          '2027-01-02',
          '2027-01-03',
        ])
          ExceptionEntry(date: d(date), type: ExceptionType.noCollection),
      ],
    );
    expect(datesOf(s, 'moyasu', '2026-12-25', '2027-01-10'), [
      '2026-12-26',
      '2026-12-29',
      // 2 January is a Saturday, but collection is closed.
      '2027-01-05',
      '2027-01-09',
    ]);
    expect(datesOf(s, 'plastic', '2026-12-25', '2027-01-10'), [
      '2026-12-30',
      '2027-01-06',
    ]);
    expect(s.on(d('2027-01-02')).cancelled, ['moyasu']);
  });

  test('days() returns every day, including empty ones', () {
    final s = CollectionSchedule(
      calendars: [
        weekly('p', ['plastic'], ['wed']),
      ],
      exceptions: const [],
    );
    final days = s.days(d('2026-11-09'), 7);
    expect(days.map((x) => '${x.date}'), [
      '2026-11-09',
      '2026-11-10',
      '2026-11-11',
      '2026-11-12',
      '2026-11-13',
      '2026-11-14',
      '2026-11-15',
    ]);
    expect(days.where((x) => !x.isEmpty).map((x) => '${x.date}'), [
      '2026-11-11',
    ]);
  });
}
