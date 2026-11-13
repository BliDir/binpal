import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../data/bundle_sync.dart';
import '../../data/sync_controller.dart';
import '../../l10n/app_localizations.dart';
import 'about_screen.dart';

/// Area, reminders, downloaded data and about. Area and reminders are
/// placeholders until their features land.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(l10n.settingsArea),
            subtitle: Text(l10n.settingsAreaNotSet),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settingsReminders),
            subtitle: Text(l10n.settingsRemindersOff),
          ),
          _DataTile(sync: AppServices.of(context).sync),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAbout),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
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
