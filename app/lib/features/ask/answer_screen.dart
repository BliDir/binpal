import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../calendar/collection_schedule.dart';
import '../../data/schedule_repository.dart';
import '../../l10n/app_localizations.dart';
import '../item/category_style.dart';
import '../item/item_screen.dart';
import '../search/item_search.dart';
import '../today/today_screen.dart' show openSource;
import 'ask_client.dart';
import 'question_search.dart';

/// The answer to a question, from the area's rules only.
///
/// What to do (the category and instructions) always comes from the cited
/// rules in the bundle; the AI's sentence is a summary under it, and the API
/// drops it if it names another category. When the rules don't settle the
/// question, or there is no answer, the ward's official contact is shown.
class AnswerScreen extends StatefulWidget {
  const AnswerScreen({super.key, required this.question});

  final String question;

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

/// Everything the screen shows once the answer is in.
class _Answered {
  const _Answered({required this.result, required this.cited, this.next});

  /// Null when no rule matched on the phone, so nothing was asked.
  final AskResult? result;

  /// The cited rules, most relevant first.
  final List<SearchHit> cited;

  /// The next collection of the first cited rule's category in the area.
  final Collection? next;
}

class _AnswerScreenState extends State<AnswerScreen> {
  Future<(_Answered, JapanDate?)>? _answer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _answer ??= _load(isJapanese(context));
  }

  Future<(_Answered, JapanDate?)> _load(bool japanese) async {
    final services = AppServices.of(context);
    final area = services.area.area;
    if (area == null) {
      return (const _Answered(result: null, cited: []), null);
    }
    final now = services.clock();
    final candidates = await QuestionSearch(services.db)
        .candidates(area.municipalityId, widget.question, now: now);
    if (candidates.isEmpty) {
      return (const _Answered(result: null, cited: []), null);
    }
    final result = await services.asks.ask(
      areaId: area.id,
      question: widget.question,
      candidates: candidates,
      japanese: japanese,
    );
    if (result case AskAnswer(:final elapsed, :final cached)) {
      debugPrint(
        'Question answered in ${elapsed.inMilliseconds} ms'
        '${cached ? ' (cached)' : ''}',
      );
    }
    final cited = result is AskAnswer && result.covered
        ? [
            for (final id in result.itemIds)
              ?candidates.where((c) => c.rule.itemId == id).firstOrNull,
          ]
        : <SearchHit>[];

    Collection? next;
    JapanDate? nextDate;
    if (cited.isNotEmpty) {
      final schedule = await ScheduleRepository(services.db)
          .forArea(area.municipalityId, area.id);
      final category = cited.first.category.id;
      for (final day in schedule.days(JapanDate.at(now), 35)) {
        final found = day.collections
            .where((c) => c.category == category)
            .firstOrNull;
        if (found != null) {
          next = found;
          nextDate = day.date;
          break;
        }
      }
    }
    return (_Answered(result: result, cited: cited, next: next), nextDate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: _answer,
        builder: (context, snapshot) {
          // A failed load (the database, say) reads as a failed answer.
          final data = snapshot.hasError
              ? (
                  const _Answered(
                    result: AskUnavailable(AskProblem.failed),
                    cited: [],
                  ),
                  null,
                )
              : snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                l10n.answerTitle,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('“${widget.question}”', style: text.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              if (data == null)
                _Checking(label: l10n.askChecking)
              else if (data.$1.cited.isNotEmpty)
                ..._covered(context, data.$1, data.$2)
              else
                ..._notCovered(context, data.$1.result),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _covered(
    BuildContext context,
    _Answered answer,
    JapanDate? nextDate,
  ) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ja = isJapanese(context);
    final first = answer.cited.first;
    final style = categoryStyle(first.category);
    final illustration = categoryIllustration(first.category);
    final sentence = (answer.result as AskAnswer).text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final next = answer.next;
    final municipality = AppServices.of(context).sync.bundle;

    return [
      Card(
        color: style.color,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 64,
                child: illustration == null
                    ? Icon(style.icon, size: 40)
                    : Image.asset(illustration, excludeFromSemantics: true),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.answerVerdict(
                        categoryLabel(context, first.category),
                      ),
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sentence != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(sentence, style: text.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(l10n.answerRulesTitle, style: text.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      for (final hit in answer.cited) ...[
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              ja ? hit.rule.nameJa : '${hit.rule.nameEn} / ${hit.rule.nameJa}',
            ),
            subtitle: Text(
              '${l10n.answerRule} · ${categoryLabel(context, hit.category)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ItemScreen(
                  rule: hit.rule,
                  category: hit.category,
                  municipality: municipality,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      Card(
        child: ListTile(
          leading: const Icon(Icons.open_in_new, color: AppColors.primary),
          title: Text(l10n.itemSource),
          subtitle: Text(Uri.parse(first.rule.sourceUrl).host),
          onTap: () => openSource(context, first.rule.sourceUrl),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Card(
        color: AppColors.lavender,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.answerHowTo, style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                ja ? first.rule.instructionsJa : first.rule.instructionsEn,
                style: text.bodyMedium,
              ),
              if (next != null && nextDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  next.putOutBy == null
                      ? l10n.answerNext(_date(locale, nextDate))
                      : l10n.answerNextBy(
                          _date(locale, nextDate),
                          _time(context, next.putOutBy!),
                        ),
                  style: text.titleSmall,
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (sentence != null)
        Text(
          l10n.answerAiNote,
          style: text.bodySmall?.copyWith(color: AppColors.secondaryInk),
        ),
    ];
  }

  List<Widget> _notCovered(BuildContext context, AskResult? result) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final services = AppServices.of(context);
    final contact = services.area.ward?.contact;
    final ja = isJapanese(context);
    final message = switch (result) {
      AskUnavailable(problem: AskProblem.offline) => l10n.answerOffline,
      AskUnavailable(problem: AskProblem.paused) => l10n.answerPaused,
      AskUnavailable(problem: AskProblem.failed) => l10n.answerFailed,
      _ => l10n.answerNotCovered,
    };
    final json = contact == null
        ? null
        : jsonDecode(contact) as Map<String, dynamic>;
    final names = json?['name'] as Map<String, dynamic>?;
    final name = names == null ? '' : names[ja ? 'ja' : 'en'] as String;
    final phone = json?['phone'] as String?;
    final url = json?['url'] as String?;

    return [
      Card(
        color: AppColors.peach,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/illustrations/question.png',
                width: 56,
                height: 56,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.answerNotCoveredBody, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      if (json != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(l10n.answerContactTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primary,
                ),
                title: Text(name),
                subtitle: phone == null ? null : Text(phone),
                trailing: phone == null
                    ? null
                    : IconButton(
                        tooltip: l10n.answerCall(phone),
                        icon: const Icon(Icons.call),
                        onPressed: () => _call(context, phone),
                      ),
              ),
              if (url != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.open_in_new,
                    color: AppColors.primary,
                  ),
                  title: Text(l10n.answerContactPage),
                  onTap: () => openSource(context, url),
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        icon: const Icon(Icons.search),
        label: Text(l10n.answerSearch),
      ),
    ];
  }

  Future<void> _call(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).itemOpenFailed;
    final called = await launchUrl(
      Uri(scheme: 'tel', path: phone.replaceAll('-', '')),
    ).catchError((Object _) => false);
    if (!called) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Checking extends StatelessWidget {
  const _Checking({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

String _date(String locale, JapanDate date) =>
    DateFormat.MMMEd(locale).format(DateTime(date.year, date.month, date.day));

/// "8:00 AM" in the phone's time format, from the bundle's "08:00".
String _time(BuildContext context, String hhmm) {
  final parts = hhmm.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  ).format(context);
}
