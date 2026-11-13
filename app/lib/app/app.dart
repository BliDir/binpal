import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'home_shell.dart';
import 'services.dart';
import 'theme.dart';

class BinPalApp extends StatefulWidget {
  const BinPalApp({super.key, required this.services});

  final AppServices services;

  @override
  State<BinPalApp> createState() => _BinPalAppState();
}

class _BinPalAppState extends State<BinPalApp> {
  @override
  void initState() {
    super.initState();
    // Starts in the background; the first screen never waits for it.
    if (widget.services.syncOnLaunch) widget.services.sync.start();
  }

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: widget.services,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: buildTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeShell(),
      ),
    );
  }
}
