import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/area/area_setup_screen.dart';
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
    // Starts in the background; the first screen never waits for it. The
    // area was read from the database before launch (see main.dart).
    if (widget.services.syncOnLaunch) widget.services.sync.start();
  }

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: widget.services,
      child: ListenableBuilder(
        listenable: widget.services.language,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: buildTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // Null follows the phone.
          locale: widget.services.language.chosen,
          // Until an area is chosen, setting it is the whole app. A new
          // bundle that drops the chosen area brings the user back here too.
          home: ListenableBuilder(
            listenable: widget.services.area,
            builder: (context, _) {
              final area = widget.services.area;
              return area.loaded && area.area == null
                  ? const AreaSetupScreen()
                  : const HomeShell();
            },
          ),
        ),
      ),
    );
  }
}
