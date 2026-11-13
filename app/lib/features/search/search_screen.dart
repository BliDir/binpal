import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../app/top_bar.dart';
import '../../data/bundle_sync.dart';
import '../../data/sync_controller.dart';
import '../../l10n/app_localizations.dart';
import '../item/category_style.dart';
import '../item/item_screen.dart';
import 'item_search.dart';

/// Offline item search over the downloaded bundle, in English or Japanese.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  /// Wait this long after the last keystroke before searching.
  static const debounce = Duration(milliseconds: 150);

  /// A search that has found nothing for this long is counted as missed.
  static const missedAfter = Duration(seconds: 2);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Timer? _missed;
  String _query = '';
  List<SearchHit>? _results;
  int _generation = 0;
  final _recorded = <String>{};

  static const _examples = ['umbrella', '傘', 'かさ'];

  @override
  void dispose() {
    _debounce?.cancel();
    _missed?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _missed?.cancel();
    _debounce = Timer(SearchScreen.debounce, () => _search(value));
  }

  void _setQuery(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _debounce?.cancel();
    _search(value);
  }

  Future<void> _search(String value) async {
    final services = AppServices.of(context);
    final bundle = services.sync.bundle;
    final generation = ++_generation;
    final query = value.trim();
    if (query.isEmpty || bundle == null) {
      setState(() {
        _query = query;
        _results = null;
      });
      return;
    }
    final results = await ItemSearch(services.db)
        .search(bundle.municipalityId, query);
    // A newer search started while this one ran; its results win.
    if (!mounted || generation != _generation) return;
    setState(() {
      _query = query;
      _results = results;
    });
    if (results.isEmpty && !_recorded.contains(query)) {
      _missed?.cancel();
      _missed = Timer(SearchScreen.missedAfter, () {
        if (_query != query || _recorded.contains(query)) return;
        _recorded.add(query);
        services.db.recordMissedSearch(query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sync = AppServices.of(context).sync;

    return Scaffold(
      appBar: const TopBar(),
      body: ListenableBuilder(
        listenable: sync,
        builder: (context, _) {
          final field = Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _setQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
                suffixIcon: _query.isEmpty && _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.searchClear,
                        icon: const Icon(Icons.close),
                        onPressed: () => _setQuery(''),
                      ),
              ),
            ),
          );

          final Widget body;
          if (sync.bundle == null) {
            body = _NoData(sync: sync);
          } else if (_query.isEmpty || _results == null) {
            body = _Intro(examples: _examples, onExample: _setQuery);
          } else if (_results!.isEmpty) {
            body = _NoResults(query: _query);
          } else {
            body = _Results(query: _query, results: _results!, sync: sync);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_query.isEmpty) const _Heading(),
              field,
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchTitle,
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(l10n.searchSubtitle, style: text.bodyLarge),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.examples, required this.onExample});

  final List<String> examples;
  final ValueChanged<String> onExample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(l10n.searchExamplesTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final example in examples)
              ActionChip(
                avatar: const Icon(Icons.search, size: 18),
                label: Text(example),
                backgroundColor: AppColors.lavender,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                onPressed: () => onExample(example),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          color: AppColors.lavender,
          child: ListTile(
            leading: const Icon(Icons.wifi_off_outlined),
            title: Text(l10n.searchOfflineTitle),
            subtitle: Text(l10n.searchOfflineBody),
          ),
        ),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData({required this.sync});

  final SyncController sync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final failed = sync.lastResult?.outcome == SyncOutcome.failed;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        if (sync.syncing) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          sync.syncing
              ? l10n.searchDownloading
              : failed
              ? l10n.searchDownloadFailed
              : l10n.searchNoAreaBody,
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (failed && !sync.syncing) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: FilledButton(
              onPressed: () => sync.refresh(force: true),
              child: Text(l10n.searchRetry),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(
          l10n.searchNoResults(query),
          style: text.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.searchNoResultsBody,
          style: text.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.query,
    required this.results,
    required this.sync,
  });

  final String query;
  final List<SearchHit> results;
  final SyncController sync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ja = isJapanese(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      itemCount: results.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Text(
            l10n.searchResultCount(results.length, query),
            style: text.bodyMedium,
          );
        }
        final hit = results[i - 1];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ItemScreen(
                  rule: hit.rule,
                  category: hit.category,
                  municipality: sync.bundle,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ja ? hit.rule.nameJa : hit.rule.nameEn,
                          style: text.titleMedium,
                        ),
                        if (!ja) Text(hit.rule.nameJa, style: text.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        CategoryChip(category: hit.category),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
