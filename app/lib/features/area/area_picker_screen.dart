import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

/// Choose the collection area by hand: ward, then town, then chōme.
///
/// This is the fallback DAI-569's GPS detection will sit on top of. Steps
/// with only one choice (a city with one ward downloaded, a town with no
/// chōme) are skipped.
class AreaPickerScreen extends StatefulWidget {
  const AreaPickerScreen({super.key});

  @override
  State<AreaPickerScreen> createState() => _AreaPickerScreenState();
}

class _AreaPickerScreenState extends State<AreaPickerScreen> {
  List<Ward>? _wards;
  List<Area>? _areas;
  Ward? _ward;
  String? _town;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_areas == null) _load();
  }

  Future<void> _load() async {
    final services = AppServices.of(context);
    final bundle = services.sync.bundle;
    if (bundle == null) {
      setState(() {
        _wards = const [];
        _areas = const [];
      });
      return;
    }
    final mid = bundle.municipalityId;
    final db = services.db;
    final wards =
        await (db.select(db.wards)
              ..where((w) => w.municipalityId.equals(mid))
              ..orderBy([(w) => OrderingTerm.asc(w.nameKana)]))
            .get();
    final areas =
        await (db.select(db.areas)
              ..where((a) => a.municipalityId.equals(mid))
              ..orderBy([
                (a) => OrderingTerm.asc(a.townKana),
                (a) => OrderingTerm.asc(a.chome),
                (a) => OrderingTerm.asc(a.id),
              ]))
            .get();
    if (!mounted) return;
    setState(() {
      _wards = wards;
      _areas = areas;
      if (wards.length == 1) _ward = wards.single;
    });
  }

  bool get _wardStep => _ward == null && (_wards?.length ?? 0) > 1;

  List<Area> get _inWard => [
    for (final a in _areas ?? const <Area>[])
      if (_ward == null || a.wardId == _ward!.id) a,
  ];

  Future<void> _choose(Area area) async {
    setState(() => _saving = true);
    final services = AppServices.of(context);
    await services.area.select(area);
    await services.reminders.reschedule();
    if (mounted) Navigator.of(context).pop(area);
  }

  void _chooseTown(String town) {
    final areas = [
      for (final a in _inWard)
        if (a.townJa == town) a,
    ];
    if (areas.length == 1) {
      _choose(areas.single);
    } else {
      setState(() => _town = town);
    }
  }

  /// Back goes up one step before leaving the screen.
  bool get _canPop =>
      _town == null && (_ward == null || (_wards?.length ?? 0) <= 1);

  void _back() => setState(() {
    if (_town != null) {
      _town = null;
    } else if ((_wards?.length ?? 0) > 1) {
      _ward = null;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ja = Localizations.localeOf(context).languageCode == 'ja';
    final text = Theme.of(context).textTheme;

    final Widget body;
    if (_areas == null || _saving) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_areas!.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(l10n.areaPickerNoData, textAlign: TextAlign.center),
      );
    } else {
      final String heading;
      final List<Widget> tiles;
      if (_wardStep) {
        heading = l10n.areaPickerWard;
        tiles = [
          for (final w in _wards!)
            _tile(
              ja ? w.nameJa : w.nameEn,
              ja ? null : w.nameJa,
              () => setState(() => _ward = w),
            ),
        ];
      } else if (_town == null) {
        heading = l10n.areaPickerTown;
        final towns = <String, Area>{};
        for (final a in _inWard) {
          towns.putIfAbsent(a.townJa, () => a);
        }
        tiles = [
          for (final a in towns.values)
            _tile(
              ja ? a.townJa : a.townEn,
              ja ? a.townKana : a.townJa,
              () => _chooseTown(a.townJa),
            ),
        ];
      } else {
        heading = l10n.areaPickerChome;
        tiles = [
          for (final a in _inWard)
            if (a.townJa == _town)
              _tile(
                ja ? a.nameJa : a.nameEn,
                ja ? null : a.nameJa,
                () => _choose(a),
              ),
        ];
      }
      body = ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: text.titleLarge),
                Text(l10n.areaPickerHint, style: text.bodyMedium),
              ],
            ),
          ),
          ...tiles,
        ],
      );
    }

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.areaPickerTitle)),
        body: body,
      ),
    );
  }

  Widget _tile(String title, String? subtitle, VoidCallback onTap) => ListTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
