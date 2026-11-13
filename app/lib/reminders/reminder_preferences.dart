import 'dart:convert';

import '../data/database.dart';

/// A time of day in Japan, for reminders.
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  factory ReminderTime.parse(String text) {
    final parts = text.split(':');
    return ReminderTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int hour;
  final int minute;

  /// Minutes since midnight, for comparing with a calendar's `put_out_by`.
  int get minutes => hour * 60 + minute;

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// What the user wants to be reminded about, and when.
class ReminderPreferences {
  const ReminderPreferences({
    this.enabled = false,
    this.categories = const {},
    this.evening = true,
    this.eveningTime = const ReminderTime(19, 0),
    this.morning = true,
    this.morningTime = const ReminderTime(7, 0),
  });

  factory ReminderPreferences.fromJson(
    Map<String, dynamic> json,
  ) => ReminderPreferences(
    enabled: json['enabled'] as bool? ?? false,
    categories: {
      for (final c in json['categories'] as List<dynamic>? ?? const [])
        c as String,
    },
    evening: json['evening'] as bool? ?? true,
    eveningTime: ReminderTime.parse(json['evening_time'] as String? ?? '19:00'),
    morning: json['morning'] as bool? ?? true,
    morningTime: ReminderTime.parse(json['morning_time'] as String? ?? '07:00'),
  );

  /// Reminders are off until the user turns them on.
  final bool enabled;

  /// Category ids to be reminded about.
  final Set<String> categories;

  /// The evening before the collection, at [eveningTime].
  final bool evening;
  final ReminderTime eveningTime;

  /// The morning of the collection, at [morningTime].
  final bool morning;
  final ReminderTime morningTime;

  bool get active => enabled && categories.isNotEmpty && (evening || morning);

  ReminderPreferences copyWith({
    bool? enabled,
    Set<String>? categories,
    bool? evening,
    ReminderTime? eveningTime,
    bool? morning,
    ReminderTime? morningTime,
  }) => ReminderPreferences(
    enabled: enabled ?? this.enabled,
    categories: categories ?? this.categories,
    evening: evening ?? this.evening,
    eveningTime: eveningTime ?? this.eveningTime,
    morning: morning ?? this.morning,
    morningTime: morningTime ?? this.morningTime,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'categories': categories.toList()..sort(),
    'evening': evening,
    'evening_time': '$eveningTime',
    'morning': morning,
    'morning_time': '$morningTime',
  };

  static const settingKey = 'reminders';

  static Future<ReminderPreferences> load(AppDatabase db) async {
    final raw = await db.setting(settingKey);
    if (raw == null) return const ReminderPreferences();
    try {
      return ReminderPreferences.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const ReminderPreferences();
    }
  }

  Future<void> save(AppDatabase db) =>
      db.setSetting(settingKey, jsonEncode(toJson()));
}
