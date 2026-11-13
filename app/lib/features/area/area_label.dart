import 'package:flutter/widgets.dart';

import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

/// "Aobadai 1-chome, Aoba Ward" or "青葉区青葉台一丁目".
String areaLabel(BuildContext context, Area area, Ward? ward) {
  final ja = Localizations.localeOf(context).languageCode == 'ja';
  final name = ja ? area.nameJa : area.nameEn;
  if (ward == null) return name;
  return AppLocalizations.of(context)
      .areaLabel(name, ja ? ward.nameJa : ward.nameEn);
}
