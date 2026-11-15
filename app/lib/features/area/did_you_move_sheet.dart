import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'area_label.dart';
import 'area_setup_screen.dart';

/// Asks "Did you move?" when [MoveCheck] says the phone has been away from
/// the saved area for a while. "Update area" opens area setup; "Not now",
/// or closing the sheet, mutes the question for a month. The area is never
/// changed without the user choosing one.
Future<void> askIfMoved(BuildContext context) async {
  final services = AppServices.of(context);
  final navigator = Navigator.of(context);
  final update = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    builder: (_) => const _DidYouMoveSheet(),
  );
  // Choosing an area resets the check (AppServices.chooseArea). Backing out
  // of setup without choosing one counts as "Not now".
  final chosen = (update ?? false)
      ? await navigator.push(
          MaterialPageRoute<Area>(builder: (_) => const AreaSetupScreen()),
        )
      : null;
  if (chosen == null) await services.moveCheck.notNow();
}

class _DidYouMoveSheet extends StatelessWidget {
  const _DidYouMoveSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final area = AppServices.of(context).area;
    final saved = area.area;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/illustrations/moving-van.png',
              height: 96,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.moveTitle,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.moveBody,
              style: text.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (saved != null) ...[
              const SizedBox(height: AppSpacing.md),
              Card(
                color: AppColors.peach,
                child: ListTile(
                  leading: const Icon(
                    Icons.place_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(l10n.moveSaved, style: text.bodySmall),
                  subtitle: Text(
                    areaLabel(context, saved, area.ward),
                    style: text.titleMedium,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(minimumTouchTarget),
              ),
              child: Text(l10n.moveUpdate),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(minimumTouchTarget),
              ),
              child: Text(l10n.moveNotNow),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.movePrivacy,
              style: text.bodySmall?.copyWith(color: AppColors.secondaryInk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
