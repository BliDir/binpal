import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../calendar/collection_schedule.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../area/area_label.dart';
import '../item/category_style.dart';
import 'report_client.dart';

/// What a report is about.
sealed class ReportTopic {
  const ReportTopic();
}

/// An item's category or instructions (from the item screen).
class ItemTopic extends ReportTopic {
  const ItemTopic(this.rule);

  final Rule rule;
}

/// The collections on a date in the user's area (from Today).
class DayTopic extends ReportTopic {
  const DayTopic(this.date);

  final JapanDate date;
}

/// An item search can't find (from search).
class MissingTopic extends ReportTopic {
  const MissingTopic(this.query);

  final String query;
}

/// Shows the "This looks wrong" sheet for [topic] in the user's area. After
/// sending, the sheet closes and a confirmation shows.
Future<void> showReportSheet(BuildContext context, ReportTopic topic) {
  final messenger = ScaffoldMessenger.of(context);
  final thanks = AppLocalizations.of(context).reportSent;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.canvas,
    builder: (_) => _ReportSheet(topic: topic),
  ).then((sent) {
    if (sent ?? false) {
      messenger.showSnackBar(SnackBar(content: Text(thanks)));
    }
  });
}

/// A "This looks wrong" link that opens the sheet for [topic].
class ReportLink extends StatelessWidget {
  const ReportLink({super.key, required this.topic});

  final ReportTopic topic;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showReportSheet(context, topic),
      icon: const Icon(Icons.flag_outlined),
      label: Text(AppLocalizations.of(context).reportLink),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.topic});

  final ReportTopic topic;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  late final TextEditingController _note;
  late ReportKind _kind;
  JapanDate? _date;
  bool _sending = false;
  ReportResult? _problem;

  @override
  void initState() {
    super.initState();
    final topic = widget.topic;
    _kind = switch (topic) {
      ItemTopic() => ReportKind.wrongCategory,
      DayTopic() => ReportKind.wrongDay,
      MissingTopic() => ReportKind.missingItem,
    };
    _date = topic is DayTopic ? topic.date : null;
    _note = TextEditingController(
      text: topic is MissingTopic ? topic.query.trim() : '',
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final services = AppServices.of(context);
    final today = JapanDate.at(services.clock());
    DateTime local(JapanDate d) => DateTime(d.year, d.month, d.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: local(_date ?? today),
      firstDate: local(today.addDays(-30)),
      lastDate: local(today.addDays(60)),
    );
    if (picked != null) {
      setState(() => _date = JapanDate(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _send() async {
    final services = AppServices.of(context);
    final area = services.area.area;
    final navigator = Navigator.of(context);
    if (area == null) return;
    setState(() {
      _sending = true;
      _problem = null;
    });
    final topic = widget.topic;
    final result = await services.reports.send(
      areaId: area.id,
      kind: _kind,
      itemId: topic is ItemTopic ? topic.rule.itemId : null,
      date: _kind == ReportKind.wrongDay ? _date?.toString() : null,
      note: _note.text,
    );
    if (!mounted) return;
    if (result == ReportResult.sent) {
      navigator.pop(true);
    } else {
      setState(() {
        _sending = false;
        _problem = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final services = AppServices.of(context);
    final area = services.area.area;
    final topic = widget.topic;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = _date;

    return Padding(
      // Keeps the comment field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.reportTitle,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.reportClose,
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(l10n.reportSubtitle, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            if (area != null)
              _Row(
                icon: Icons.place_outlined,
                label: l10n.reportArea,
                value: areaLabel(context, area, services.area.ward),
              ),
            if (topic is ItemTopic) ...[
              const SizedBox(height: AppSpacing.sm),
              _Row(
                icon: Icons.inventory_2_outlined,
                label: l10n.reportItem,
                value: isJapanese(context)
                    ? topic.rule.nameJa
                    : topic.rule.nameEn,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.reportWhatsWrong, style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final (kind, label) in [
                    (ReportKind.wrongCategory, l10n.reportKindCategory),
                    (ReportKind.wrongInstructions, l10n.reportKindInstructions),
                    (ReportKind.other, l10n.reportKindOther),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ],
              ),
            ],
            if (topic is DayTopic && date != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _Row(
                icon: Icons.event_outlined,
                label: l10n.reportDate,
                value: DateFormat.MMMEd(locale)
                    .format(DateTime(date.year, date.month, date.day)),
                onTap: _pickDate,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 5,
              maxLength: ReportClient.maxNoteLength,
              decoration: InputDecoration(
                labelText: topic is MissingTopic
                    ? l10n.reportMissingLabel
                    : l10n.reportComment,
                hintText: topic is MissingTopic
                    ? l10n.reportMissingHint
                    : l10n.reportCommentHint,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
            ),
            Text(
              l10n.reportPublic,
              style: text.bodySmall?.copyWith(color: AppColors.secondaryInk),
            ),
            if (_problem != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(switch (_problem!) {
                ReportResult.offline => l10n.reportOffline,
                ReportResult.limited => l10n.reportLimited,
                _ => l10n.reportFailed,
              }, style: text.bodyMedium?.copyWith(color: AppColors.primary)),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _sending || area == null ? null : _send,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(minimumTouchTarget),
              ),
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(l10n.reportSend),
            ),
          ],
        ),
      ),
    );
  }
}

/// A peach row like the design's Area and Collection date fields.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.peach,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: text.titleSmall),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value,
                  style: text.bodyMedium,
                  textAlign: TextAlign.end,
                ),
              ),
              if (onTap != null) const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }
}
