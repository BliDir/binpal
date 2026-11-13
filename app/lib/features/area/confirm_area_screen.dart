import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../area/area_finder.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'area_label.dart';
import 'area_picker_screen.dart';

/// "Is this your area?" for what the phone's location found. Near a
/// boundary, the areas on the other side are offered too. Pops with the
/// saved [Area].
class ConfirmAreaScreen extends StatefulWidget {
  const ConfirmAreaScreen({super.key, required this.found});

  final FoundAreas found;

  @override
  State<ConfirmAreaScreen> createState() => _ConfirmAreaScreenState();
}

class _ConfirmAreaScreenState extends State<ConfirmAreaScreen> {
  late Area _selected = widget.found.areas.first;
  bool _saving = false;

  Ward? _wardOf(Area area) =>
      area.wardId == null ? null : widget.found.wards[area.wardId];

  Future<void> _confirm() async {
    setState(() => _saving = true);
    await AppServices.of(context).chooseArea(_selected);
    if (mounted) Navigator.of(context).pop(_selected);
  }

  Future<void> _chooseAnother() async {
    final chosen = await Navigator.of(
      context,
    ).push(MaterialPageRoute<Area>(builder: (_) => const AreaPickerScreen()));
    if (chosen != null && mounted) Navigator.of(context).pop(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final [first, ...nearby] = widget.found.areas;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.confirmTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Image.asset(
                'assets/illustrations/map-pin.png',
                height: 140,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.confirmHeading,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.confirmBody(areaLabel(context, first, _wardOf(first))),
              style: text.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _option(first),
            if (nearby.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.confirmNearby, style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.confirmNearbyHint, style: text.bodyMedium),
              for (final area in nearby) ...[
                const SizedBox(height: AppSpacing.sm),
                _option(area),
              ],
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _confirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(minimumTouchTarget),
              ),
              child: Text(l10n.confirmButton),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _saving ? null : _chooseAnother,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(minimumTouchTarget),
              ),
              child: Text(l10n.confirmOther),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(Area area) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final selected = area.id == _selected.id;
    final ward = _wardOf(area);
    final bundle = AppServices.of(context).sync.bundle;
    final city = bundle == null ? null : (ja ? bundle.nameJa : bundle.nameEn);
    final wardName = ward == null ? null : (ja ? ward.nameJa : ward.nameEn);
    final where = switch ((wardName, city)) {
      (final w?, final c?) => l10n.confirmWardCity(w, c),
      (final w?, null) => w,
      (null, final c) => c,
    };

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Card(
        color: selected ? AppColors.peach : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: _saving ? null : () => setState(() => _selected = area),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.secondaryInk,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ja ? area.nameJa : area.nameEn,
                        style: text.titleMedium,
                      ),
                      if (where != null) Text(where, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
