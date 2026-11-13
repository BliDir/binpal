import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices.live();
  // Read the chosen area first, so the first frame is already the right
  // screen: area setup or Today.
  await services.area.load();
  runApp(BinPalApp(services: services));
}
