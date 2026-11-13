import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/bundle_sync.dart';
import '../../data/sync_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../reminders/reminder_preferences.dart';
import '../area/area_label.dart';
import '../area/area_picker_screen.dart';
import '../reminders/reminder_settings_screen.dart';
import 'about_screen.dart';

/// Area, reminders, downloaded data and about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<ReminderPreferences>? _reminders;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reminders ??= ReminderPreferences.load(AppServices.of(context).db);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (!mounted) return;
    final reminders = ReminderPreferences.load(AppServices.of(context).db);
    setState(() {
      _reminders = reminders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = AppServices.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListenableBuilder(
            listenable: services.area,
            builder: (context, _) {
              final area = services.area.area;
              return ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(l10n.settingsArea),
                subtitle: Text(
                  area == null
                      ? l10n.settingsAreaNotSet
                      : areaLabel(context, area, services.area.ward),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(const AreaPickerScreen()),
              );
            },
          ),
          FutureBuilder(
            future: _reminders,
            builder: (context, snapshot) => ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.settingsReminders),
              subtitle: Text(_reminderSummary(context, snapshot.data)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(const ReminderSettingsScreen()),
            ),
          ),
          _DataTile(sync: services.sync),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAbout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(const AboutScreen()),
          ),
        ],
      ),
    );
  }
}

String _reminderSummary(BuildContext context, ReminderPreferences? p) {
  final l10n = AppLocalizations.of(context);
  if (p == null || !p.active) return l10n.settingsRemindersOff;
  String time(ReminderTime t) =>
      TimeOfDay(hour: t.hour, minute: t.minute).format(context);
  return [
    if (p.evening) l10n.remindersSummaryEvening(time(p.eveningTime)),
    if (p.morning) l10n.remindersSummaryMorning(time(p.morningTime)),
  ].join('\n');
}

/// Which bundle is on the device, and a way to retry a failed download.
class _DataTile extends StatelessWidget {
  const _DataTile({required this.sync});

  final SyncController sync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final bundle = sync.bundle;
        final failed = sync.lastResult?.outcome == SyncOutcome.failed;
        final ja = Localizations.localeOf(context).languageCode == 'ja';
        final String status;
        if (bundle != null) {
          final version = l10n.settingsDataVersion(
            ja ? bundle.nameJa : bundle.nameEn,
            bundle.bundleVersion,
          );
          status = failed ? '$version\n${l10n.settingsDataStale}' : version;
        } else if (sync.syncing) {
          status = l10n.settingsDataDownloading;
        } else {
          status = failed ? l10n.settingsDataFailed : l10n.settingsDataNone;
        }
        return ListTile(
          leading: const Icon(Icons.download_done_outlined),
          title: Text(l10n.settingsData),
          subtitle: Text(status),
          isThreeLine: bundle != null && failed,
          onTap: sync.syncing ? null : () => sync.refresh(force: true),
        );
      },
    );
  }
}
