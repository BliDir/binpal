import 'package:flutter/material.dart';

import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Shared top bar for the main tabs: area chip on the left, settings on the right.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      titleSpacing: AppSpacing.md,
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Chip(
          avatar: const Icon(Icons.place_outlined, color: AppColors.primary),
          label: Text(l10n.areaNotSet),
          backgroundColor: AppColors.peach,
          side: BorderSide.none,
          shape: const StadiumBorder(),
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
