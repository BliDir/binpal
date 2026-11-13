import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';

/// A stronger version of each card colour, for calendar dots and legends.
final _dots = {
  AppColors.peach: Color(0xFFE0782F),
  AppColors.lavender: Color(0xFF9C6CC6),
  AppColors.sage: Color(0xFF7C8F3A),
  AppColors.outline: Color(0xFF8C7A6E),
};

/// The dot colour for [category] in the calendar.
Color categoryDot(WasteCategory category) =>
    _dots[categoryStyle(category).color] ?? AppColors.secondaryInk;

/// The illustration for [category] from `assets/illustrations/`, if one fits.
/// Bundles only say which shared type a category is, so batteries are told
/// apart from other hazardous waste (spray cans) by name.
String? categoryIllustration(WasteCategory category) {
  final name = switch (category.common) {
    'burnable' => 'burnable',
    'non_burnable' => 'non-burnable',
    'plastic' => 'plastic-packaging',
    'pet_bottles' => 'pet-bottle',
    'cans_bottles' => 'aluminum-can',
    'paper' => 'paper-cardboard',
    'hazardous' when category.nameEn.toLowerCase().contains('batter') =>
      'batteries',
    _ => null,
  };
  return name == null ? null : 'assets/illustrations/$name.png';
}

/// Icon and colour for a category, from its shared `common` type.
({IconData icon, Color color}) categoryStyle(
  WasteCategory category,
) => switch (category.common) {
  'burnable' => (
    icon: Icons.local_fire_department_outlined,
    color: AppColors.peach,
  ),
  'non_burnable' => (icon: Icons.delete_outline, color: AppColors.lavender),
  'plastic' => (icon: Icons.recycling, color: AppColors.lavender),
  'cans_bottles' => (icon: Icons.local_drink_outlined, color: AppColors.sage),
  'pet_bottles' => (icon: Icons.local_drink_outlined, color: AppColors.sage),
  'resources' => (icon: Icons.recycling, color: AppColors.sage),
  'paper' => (icon: Icons.newspaper_outlined, color: AppColors.sage),
  'hazardous' => (icon: Icons.warning_amber_rounded, color: AppColors.peach),
  'bulky' => (icon: Icons.chair_outlined, color: AppColors.lavender),
  'not_collected' => (icon: Icons.block, color: AppColors.outline),
  _ => (icon: Icons.help_outline, color: AppColors.outline),
};

/// Whether the interface is in Japanese.
bool isJapanese(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ja';

/// The category's name: English with the Japanese after it in the English
/// interface, so it can be matched to signs and stickers; Japanese only in
/// the Japanese interface.
String categoryLabel(BuildContext context, WasteCategory category) =>
    isJapanese(context)
    ? category.nameJa
    : '${category.nameEn} / ${category.nameJa}';

/// A rounded chip with the category's icon, colour and name.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final WasteCategory category;

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 18, color: AppColors.ink),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              categoryLabel(context, category),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
