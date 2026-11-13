import 'package:binpal/reminders/reminder_notifications.dart';

class ScheduledNotification {
  const ScheduledNotification(this.id, this.at, this.title, this.body);

  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => '$id ${at.toUtc().toIso8601String()} $title | $body';
}

/// Records what would be scheduled, and enforces iOS's limit of 64 pending
/// notifications by failing loudly instead of dropping them silently.
class FakeReminderNotifications implements ReminderNotifications {
  final pending = <int, ScheduledNotification>{};
  bool permission = true;
  int permissionRequests = 0;

  /// Most notifications pending at any one time.
  int peak = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String channelName,
  }) async {
    pending[id] = ScheduledNotification(id, at, title, body);
    if (pending.length > 64) {
      throw StateError('more than 64 pending notifications');
    }
    if (pending.length > peak) peak = pending.length;
  }

  @override
  Future<void> cancelAll() async => pending.clear();

  @override
  Future<List<int>> pendingIds() async => pending.keys.toList();

  List<ScheduledNotification> get sorted =>
      pending.values.toList()..sort((a, b) => a.at.compareTo(b.at));
}
