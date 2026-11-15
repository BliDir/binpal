import 'dart:math';

import 'database.dart';

/// Where the thin API (`../api/`) is served: photo check's AI fallback and
/// "this looks wrong" reports. Override at build time with
/// `--dart-define=API_BASE_URL=…`.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.blidir.fun',
);

/// A random id made on first use, so the API can count per-install limits.
/// It identifies nothing else: no account, device or location.
const installIdSettingKey = 'install_id';

/// This install's random id, made and stored the first time.
Future<String> installId(AppDatabase db, {Random? random}) async {
  final stored = await db.setting(installIdSettingKey);
  if (stored != null) return stored;
  final id = _uuidV4(random ?? Random.secure());
  await db.setSetting(installIdSettingKey, id);
  return id;
}

String _uuidV4(Random random) {
  final b = List<int>.generate(16, (_) => random.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}
