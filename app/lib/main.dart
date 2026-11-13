import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(BinPalApp(services: AppServices.live()));
}
