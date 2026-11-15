import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../item/category_style.dart';
import '../item/item_screen.dart';
import '../search/item_search.dart';
import 'identify_client.dart';
import 'photo_check_screen.dart';
import 'photo_image.dart';
import 'photo_matcher.dart';

/// What the phone found in a photo: the match when it is confident, or the
/// likely items to choose from while the AI is asked in the background.
///
/// The photo file is deleted when this screen closes.
class PhotoResultScreen extends StatefulWidget {
  const PhotoResultScreen({
    super.key,
    required this.photoPath,
    required this.signals,
    required this.match,
  });

  final String photoPath;
  final PhotoSignals signals;
  final PhotoMatch match;

  @override
  State<PhotoResultScreen> createState() => _PhotoResultScreenState();
}

class _PhotoResultScreenState extends State<PhotoResultScreen> {
  /// The user said the confident match is wrong.
  bool _choosing = false;
  bool _asking = false;
  AiResult? _ai;

  /// The AI's answer as a confident answer, when its item or category is in
  /// the bundle.
  PhotoAnswer? _aiAnswer;

  @override
  void initState() {
    super.initState();
    if (widget.match.answer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askAi());
    }
  }

  @override
  void dispose() {
    // Photos are never kept, on the phone or the server.
    File(widget.photoPath).delete().ignore();
    super.dispose();
  }

  Future<void> _askAi() async {
    if (_asking || _ai != null || widget.match.candidates.isEmpty) return;
    final services = AppServices.of(context);
    final area = services.area.area;
    if (area == null) return;
    setState(() => _asking = true);

    AiResult result;
    try {
      final jpeg = await resizeForUpload(
        await File(widget.photoPath).readAsBytes(),
      );
      result = await services.identify.identify(
        areaId: area.id,
        jpeg: jpeg,
        candidates: widget.match.candidates,
        labels: widget.signals.logLabels,
      );
    } on Object catch (e) {
      debugPrint('Photo check AI failed: $e');
      result = const AiUnavailable(AiProblem.failed);
    }

    PhotoAnswer? answer;
    if (result case AiAnswer(
      :final itemId,
      :final categoryId,
      :final elapsed,
      :final cached,
    )) {
      debugPrint(
        'Photo check AI: ${elapsed.inMilliseconds} ms'
        '${cached ? ' (cached)' : ''}',
      );
      final item = widget.match.candidates
          .where((c) => c.rule.itemId == itemId)
          .firstOrNull;
      final category =
          item?.category ??
          await PhotoMatcher(services.db)
              .categoryById(area.municipalityId, categoryId);
      if (category != null) {
        answer = PhotoAnswer(
          category: category,
          item: item,
          source: PhotoAnswerSource.ai,
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _asking = false;
      _ai = result;
      _aiAnswer = answer;
    });
  }

  void _notRight() {
    setState(() => _choosing = true);
    _askAi();
  }

  /// Opens [hit] and remembers it for photos with the same labels and marks.
  Future<void> _choose(SearchHit hit) async {
    final services = AppServices.of(context);
    final navigator = Navigator.of(context);
    final municipality = services.sync.bundle;
    if (municipality != null) {
      await PhotoMatcher(
        services.db,
        clock: services.clock,
      ).remember(municipality.municipalityId, widget.signals, hit.rule.itemId);
    }
    _open(navigator, hit);
  }

  void _open(NavigatorState navigator, SearchHit hit) {
    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => ItemScreen(
          rule: hit.rule,
          category: hit.category,
          municipality: AppServices.of(context).sync.bundle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answer = widget.match.answer;
    return Scaffold(
      appBar: AppBar(),
      body: answer != null && !_choosing
          ? _MatchView(
              photoPath: widget.photoPath,
              answer: answer,
              candidates: widget.match.candidates,
              onOpen: (hit) => _open(Navigator.of(context), hit),
              onChoose: _choose,
              onNotRight: _notRight,
            )
          : _ChooseView(
              modelsMissing: widget.signals.modelsMissing,
              candidates: widget.match.candidates,
              asking: _asking,
              ai: _ai,
              aiAnswer: _aiAnswer,
              onChoose: _choose,
            ),
    );
  }
}

/// "Match result": the photo, the item or category the phone is sure of,
/// and how to put it out.
class _MatchView extends StatelessWidget {
  const _MatchView({
    required this.photoPath,
    required this.answer,
    required this.candidates,
    required this.onOpen,
    required this.onChoose,
    required this.onNotRight,
  });

  final String photoPath;
  final PhotoAnswer answer;
  final List<SearchHit> candidates;
  final ValueChanged<SearchHit> onOpen;
  final ValueChanged<SearchHit> onChoose;
  final VoidCallback onNotRight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ja = isJapanese(context);
    final item = answer.item;
    final category = answer.category;
    final description = ja ? category.descriptionJa : category.descriptionEn;
    final inCategory = [
      for (final c in candidates)
        if (c.category.id == category.id) c,
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n.photoResultTitle,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          color: AppColors.lavender,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card / 2),
                  child: Image.file(
                    File(photoPath),
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Badge(source: answer.source),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        item == null
                            ? categoryLabel(context, category)
                            : _itemName(context, item.rule),
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CategoryCard(category: category),
        const SizedBox(height: AppSpacing.md),
        if (item != null) ...[
          Text(l10n.photoGuidance, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ja ? item.rule.instructionsJa : item.rule.instructionsEn,
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => onOpen(item),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.photoViewRule),
          ),
        ] else ...[
          if (description != null) ...[
            Text(description, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          if (inCategory.isNotEmpty) ...[
            Text(l10n.photoWhichInCategory, style: text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final hit in inCategory.take(8)) ...[
              _CandidateCard(hit: hit, onTap: () => onChoose(hit)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onNotRight, child: Text(l10n.photoNotRight)),
      ],
    );
  }
}

/// "Which item is this?": the likely items, with the AI's suggestion first
/// once it arrives.
class _ChooseView extends StatelessWidget {
  const _ChooseView({
    required this.modelsMissing,
    required this.candidates,
    required this.asking,
    required this.ai,
    required this.aiAnswer,
    required this.onChoose,
  });

  final bool modelsMissing;
  final List<SearchHit> candidates;
  final bool asking;
  final AiResult? ai;
  final PhotoAnswer? aiAnswer;
  final ValueChanged<SearchHit> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final aiItem = aiAnswer?.item;

    if (candidates.isEmpty) return _Nothing(modelsMissing: modelsMissing);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n.photoWhichTitle,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.photoWhichBody, style: text.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        if (asking)
          _Status(
            leading: const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            message: l10n.photoAsking,
          )
        else if (aiItem != null)
          _CandidateCard(
            hit: aiItem,
            badge: const _Badge(source: PhotoAnswerSource.ai),
            highlighted: true,
            onTap: () => onChoose(aiItem),
          )
        else if (aiAnswer != null)
          _Status(
            leading: Icon(categoryStyle(aiAnswer!.category).icon),
            message: l10n.photoCategoryOnly(
              categoryLabel(context, aiAnswer!.category),
            ),
          )
        else if (ai case AiUnavailable(:final problem))
          _Status(
            leading: Icon(
              problem == AiProblem.offline
                  ? Icons.wifi_off_outlined
                  : Icons.info_outline,
            ),
            message: switch (problem) {
              AiProblem.offline => l10n.photoAiOffline,
              AiProblem.paused => l10n.photoAiPaused,
              AiProblem.noAnswer => l10n.photoAiNoAnswer,
              AiProblem.failed => l10n.photoAiFailed,
            },
          ),
        const SizedBox(height: AppSpacing.md),
        for (final hit in candidates.take(8))
          if (hit.rule.itemId != aiItem?.rule.itemId) ...[
            _CandidateCard(hit: hit, onTap: () => onChoose(hit)),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.sm),
        const _SearchByName(),
      ],
    );
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing({required this.modelsMissing});

  final bool modelsMissing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const Icon(Icons.image_search, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.photoNothingTitle,
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          modelsMissing ? l10n.photoModelsMissing : l10n.photoNothingBody,
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const PhotoCheckScreen()),
          ),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.photoTryAgain),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _SearchByName(),
      ],
    );
  }
}

/// Back to the Search tab, where photo check was opened.
class _SearchByName extends StatelessWidget {
  const _SearchByName();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
      icon: const Icon(Icons.search),
      label: Text(AppLocalizations.of(context).photoSearchByName),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.source});

  final PhotoAnswerSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(switch (source) {
        PhotoAnswerSource.remembered => l10n.photoRemembered,
        PhotoAnswerSource.mark => l10n.photoFromMark,
        PhotoAnswerSource.ai => l10n.photoAiMatch,
        PhotoAnswerSource.label ||
        PhotoAnswerSource.sharedCategory => l10n.photoLikelyMatch,
      }, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final WasteCategory category;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category);
    final illustration = categoryIllustration(category);
    return Card(
      color: style.color,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 72,
              child: illustration == null
                  ? Icon(style.icon, size: 40)
                  : Image.asset(illustration, excludeFromSemantics: true),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                categoryLabel(context, category),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.hit,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  final SearchHit hit;
  final VoidCallback onTap;
  final Widget? badge;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = categoryStyle(hit.category);
    final illustration = categoryIllustration(hit.category);
    return Card(
      color: highlighted ? AppColors.lavender : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 48,
                child: illustration == null
                    ? Icon(style.icon)
                    : Image.asset(illustration, excludeFromSemantics: true),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null) ...[
                      badge!,
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(_itemName(context, hit.rule), style: text.titleMedium),
                    Text(
                      categoryLabel(context, hit.category),
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.leading, required this.message});

  final Widget leading;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.peach,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Umbrella / 傘" in English, with the Japanese the city uses; Japanese
/// only in the Japanese interface.
String _itemName(BuildContext context, Rule rule) =>
    isJapanese(context) ? rule.nameJa : '${rule.nameEn} / ${rule.nameJa}';
