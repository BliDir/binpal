import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../area/area_finder.dart';
import '../../area/location_source.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../settings/about_screen.dart';
import 'area_picker_screen.dart';
import 'confirm_area_screen.dart';

enum _Busy { none, locating, downloading }

/// Sets the collection area: from the phone's location, confirmed by the
/// user, or chosen from the list.
///
/// It is the whole app until an area is chosen, and is pushed from settings
/// to change it; pushed, it pops with the chosen [Area].
class AreaSetupScreen extends StatefulWidget {
  const AreaSetupScreen({super.key});

  @override
  State<AreaSetupScreen> createState() => _AreaSetupScreenState();
}

class _AreaSetupScreenState extends State<AreaSetupScreen> {
  var _busy = _Busy.none;

  /// Why the last "Use my location" found nothing to confirm.
  FindResult? _failure;

  Future<void> _useLocation() async {
    setState(() {
      _busy = _Busy.locating;
      _failure = null;
    });
    final result = await findArea(
      AppServices.of(context),
      onDownload: () {
        if (mounted) setState(() => _busy = _Busy.downloading);
      },
    );
    if (!mounted) return;
    setState(() => _busy = _Busy.none);
    if (result is FoundAreas) {
      _done(
        await Navigator.of(context).push(
          MaterialPageRoute<Area>(
            builder: (_) => ConfirmAreaScreen(found: result),
          ),
        ),
      );
    } else {
      setState(() => _failure = result);
    }
  }

  Future<void> _chooseManually() async {
    _done(
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<Area>(builder: (_) => const AreaPickerScreen())),
    );
  }

  /// At the root the app moves on by itself once an area is saved; pushed
  /// from settings, go back there.
  void _done(Area? chosen) {
    if (chosen == null || !mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final pushed = ModalRoute.of(context)?.canPop ?? false;
    final busy = _busy != _Busy.none;

    return Scaffold(
      appBar: pushed ? AppBar(title: Text(l10n.areaPickerTitle)) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!pushed) ...[
              Center(
                child: Image.asset(
                  AboutScreen.logoAsset,
                  height: 48,
                  semanticLabel: l10n.logoLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Center(
              child: Image.asset(
                _busy == _Busy.downloading
                    ? 'assets/illustrations/download.png'
                    : 'assets/illustrations/neighborhood.png',
                height: 160,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.setupTitle,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.setupBody, style: text.bodyLarge),
            const SizedBox(height: AppSpacing.lg),
            if (busy)
              _Progress(
                _busy == _Busy.downloading
                    ? l10n.setupDownloadingMap
                    : l10n.setupLocating,
              )
            else if (_failure case final failure?)
              _Failure(failure),
            if (busy || _failure != null) const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: busy ? null : _useLocation,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(
                _failure == null ? l10n.setupUseLocation : l10n.setupTryAgain,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(minimumTouchTarget),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: busy ? null : _chooseManually,
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.setupChooseManually),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(minimumTouchTarget),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              color: AppColors.lavender,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.setupPrivacyTitle, style: text.titleSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.setupPrivacyBody, style: text.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// Why location didn't find an area, and the system settings that fix it
/// when there is one.
class _Failure extends StatelessWidget {
  const _Failure(this.failure);

  final FindResult failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final problem = switch (failure) {
      NoLocation(:final problem) => problem,
      _ => null,
    };
    final message = switch (failure) {
      NoLocation(problem: LocationProblem.denied) => l10n.setupDenied,
      NoLocation(problem: LocationProblem.deniedForever) =>
        l10n.setupDeniedForever,
      NoLocation(problem: LocationProblem.serviceOff) => l10n.setupServiceOff,
      NoLocation(problem: LocationProblem.unavailable) => l10n.setupUnavailable,
      MapFailed() => l10n.setupMapFailed,
      NoAreaData() => l10n.setupDataFailed,
      NotCovered(:final place?) => l10n.setupNotCovered(place),
      NotCovered() || FoundAreas() => l10n.setupOutside,
    };
    final canFix =
        problem == LocationProblem.deniedForever ||
        problem == LocationProblem.serviceOff;

    return Semantics(
      liveRegion: true,
      child: Card(
        color: AppColors.peach,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (canFix)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () =>
                        AppServices.of(context).location.openSettings(problem!),
                    child: Text(l10n.setupOpenSettings),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
