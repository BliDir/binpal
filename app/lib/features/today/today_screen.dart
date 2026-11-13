import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../app/top_bar.dart';
import '../../calendar/collection_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../reminders/reminder_preferences.dart';
import '../area/area_setup_screen.dart';
import '../calendar/calendar_screen.dart';
import '../item/category_style.dart';
import '../reminders/reminder_settings_screen.dart';
import 'area_schedule.dart';

/// Without a successful check for this long, Today says the schedule may be
/// out of date.
const staleAfter = Duration(days: 14);

/// Prints when Today's content is first shown, for measuring cold start
/// (`--dart-define=STARTUP_LOG=true`).
const _startupLog = bool.fromEnvironment('STARTUP_LOG');
var _startupLogged = false;

/// Today's and tomorrow's collections for the user's area, from local data
/// only: nothing here waits for the network.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.onOpenSearch});

  /// Switches to the Search tab.
  final VoidCallback? onOpenSearch;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  Future<AreaSchedule?>? _data;
  Future<ReminderPreferences>? _reminders;
  String? _loadedFor;

  DateTime _now() => AppServices.of(context).clock();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A new day may have started while the app was in the background.
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  /// Reloads when the area or the stored bundle changes.
  void _ensureLoaded(AppServices services) {
    final area = services.area.area;
    final key = '${area?.id}/${services.sync.bundle?.bundleVersion}';
    if (key == _loadedFor) return;
    _loadedFor = key;
    _data = area == null
        ? Future.value()
        : AreaSchedule.load(services.db, area, services.area.ward);
    _reminders = ReminderPreferences.load(services.db);
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
    final services = AppServices.of(context);
    return Scaffold(
      appBar: const TopBar(),
      body: ListenableBuilder(
        listenable: Listenable.merge([services.area, services.sync]),
        builder: (context, _) {
          _ensureLoaded(services);
          return FutureBuilder(
            future: _data,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (_startupLog && data != null && !_startupLogged) {
                _startupLogged = true;
                // ignore: avoid_print
                print('BinPal startup: Today content shown');
              }
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _Heading(now: _now()),
                  const SizedBox(height: AppSpacing.md),
                  if (services.area.area == null)
                    _NoArea(onChoose: () => _open(const AreaSetupScreen()))
                  else if (data == null)
                    const SizedBox.shrink()
                  else
                    ..._content(context, services, data),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppServices services,
    AreaSchedule data,
  ) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = JapanDate.at(_now());
    final todayDay = data.schedule.on(today);
    final tomorrow = data.schedule.on(today.addDays(1));
    final tomorrowLabel = DateFormat.MMMEd(locale).format(
      DateTime(tomorrow.date.year, tomorrow.date.month, tomorrow.date.day),
    );
    final lastChecked = services.sync.lastChecked;
    final stale =
        lastChecked == null || _now().difference(lastChecked) > staleAfter;

    return [
      _DayCard(data: data, day: todayDay, large: true),
      const SizedBox(height: AppSpacing.md),
      _SearchShortcut(onTap: widget.onOpenSearch),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.todayTomorrow(tomorrowLabel), style: text.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      _DayCard(data: data, day: tomorrow, large: false),
      if (stale) ...[
        const SizedBox(height: AppSpacing.md),
        _StaleNotice(
          since: lastChecked ?? services.sync.bundle?.importedAt,
          sourceUrl: data.sourceUrl,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Card(
        child: Column(
          children: [
            FutureBuilder(
              future: _reminders,
              builder: (context, snapshot) => ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.todayReminders),
                subtitle: Text(_reminderSummary(context, snapshot.data)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(const ReminderSettingsScreen()),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
              title: Text(l10n.todayViewCalendar),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(CalendarScreen(data: data, now: _now)),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Freshness(
        checked: lastChecked ?? services.sync.bundle?.importedAt,
        source: data.ward == null
            ? null
            : (isJapanese(context) ? data.ward!.nameJa : data.ward!.nameEn),
        sourceUrl: data.sourceUrl,
      ),
    ];
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

Future<void> openSource(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).itemOpenFailed;
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  ).catchError((Object _) => false);
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// "Put out by 8:00 AM", in the phone's time format.
String putOutLabel(BuildContext context, String hhmm) {
  final parts = hhmm.split(':');
  final time = TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
  return AppLocalizations.of(context).todayPutOutBy(time.format(context));
}

class _Heading extends StatelessWidget {
  const _Heading({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = JapanDate.at(now);
    final date = DateFormat.MMMMEEEEd(locale)
        .format(DateTime(today.year, today.month, today.day));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.todayTitle,
          style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(date, style: text.titleMedium),
      ],
    );
  }
}

class _NoArea extends StatelessWidget {
  const _NoArea({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      color: AppColors.peach,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onChoose,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.todayNoAreaTitle, style: text.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.todayNoAreaBody, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What goes out on one day: the first category large, with its
/// illustration and put-out time, and the others that share the day below.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.data, required this.day, required this.large});

  final AreaSchedule data;
  final CollectionDay day;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ja = isJapanese(context);
    final collections = data.collectionsOn(day);
    final notes = [for (final n in day.notes) ?(ja ? n.noteJa : n.noteEn)];

    if (collections.isEmpty) {
      return Card(
        color: AppColors.peach.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: large ? 56 : 40,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      large
                          ? l10n.todayNoCollection
                          : l10n.todayNoCollectionTomorrow,
                      style: large ? text.titleLarge : text.titleMedium,
                    ),
                    if (large || notes.isNotEmpty)
                      Text(
                        notes.isNotEmpty
                            ? notes.join(' ')
                            : l10n.todayNoCollectionBody,
                        style: text.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final (first, category) = collections.first;
    final others = collections.skip(1).map((e) => e.$2).toList();
    final style = categoryStyle(category);
    final illustration = categoryIllustration(category);
    final size = large ? 104.0 : 64.0;

    return Card(
      color: style.color.withValues(alpha: large ? 0.8 : 0.6),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SizedBox.square(
              dimension: size,
              child: illustration == null
                  ? Icon(style.icon, size: size * 0.6, color: AppColors.ink)
                  : Image.asset(illustration, excludeFromSemantics: true),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ja ? category.nameJa : category.nameEn,
                    style: (large ? text.headlineSmall : text.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (!ja) Text(category.nameJa, style: text.bodyMedium),
                  if (first.putOutBy != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _Pill(
                      label: putOutLabel(context, first.putOutBy!),
                      strong: large,
                    ),
                  ],
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.todayAlso(
                        others
                            .map((c) => ja ? c.nameJa : c.nameEn)
                            .join(l10n.reminderListSeparator),
                      ),
                      style: text.bodyMedium,
                    ),
                  ],
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(notes.join(' '), style: text.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.strong});

  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: strong ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: text.labelLarge?.copyWith(
          color: strong ? AppColors.onPrimary : AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SearchShortcut extends StatelessWidget {
  const _SearchShortcut({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.outline)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.todaySearchHint,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.secondaryInk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaleNotice extends StatelessWidget {
  const _StaleNotice({required this.since, required this.sourceUrl});

  final DateTime? since;
  final String? sourceUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = since == null ? '—' : DateFormat.yMMMd(locale).format(since!);
    return Card(
      color: AppColors.peach.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.todayStaleTitle, style: text.titleMedium),
                  Text(l10n.todayStaleBody(date), style: text.bodyMedium),
                  if (sourceUrl != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => openSource(context, sourceUrl!),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(l10n.todayStaleLink),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Checked 13 Nov 2026 · Aoba Ward", linking to the official page.
class _Freshness extends StatelessWidget {
  const _Freshness({
    required this.checked,
    required this.source,
    required this.sourceUrl,
  });

  final DateTime? checked;
  final String? source;
  final String? sourceUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (checked != null)
          InkWell(
            onTap: sourceUrl == null
                ? null
                : () => openSource(context, sourceUrl!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.todayChecked(
                        DateFormat.yMMMd(locale).format(checked!),
                        source ?? '',
                      ),
                      style: text.bodySmall,
                    ),
                  ),
                  if (sourceUrl != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.open_in_new, size: 14),
                  ],
                ],
              ),
            ),
          ),
        Row(
          children: [
            const Icon(Icons.wifi_off_outlined, size: 14),
            const SizedBox(width: AppSpacing.xs),
            Text(l10n.todayOffline, style: text.bodySmall),
          ],
        ),
      ],
    );
  }
}
