import 'package:flutter/material.dart';

import '../features/area/area_label.dart';
import '../features/area/area_picker_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';
import 'services.dart';
import 'theme.dart';

/// Shared top bar for the main tabs: area chip on the left, settings on the right.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final area = AppServices.of(context).area;
    return AppBar(
      titleSpacing: AppSpacing.md,
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ListenableBuilder(
          listenable: area,
          builder: (context, _) => ActionChip(
            avatar: const Icon(Icons.place_outlined, color: AppColors.primary),
            label: Text(
              area.area == null
                  ? l10n.areaNotSet
                  : areaLabel(context, area.area!, area.ward),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppColors.peach,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AreaPickerScreen()),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: l10n.settingsTooltip,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
