import 'package:flutter/material.dart';

import '../features/area/did_you_move_sheet.dart';
import '../features/search/search_screen.dart';
import '../features/today/today_screen.dart';
import '../l10n/app_localizations.dart';
import 'services.dart';

/// Bottom navigation between the two main tabs. Settings is pushed on top
/// from the gear in each tab's top bar.
///
/// When it opens and whenever the app comes back to the foreground, it
/// checks for a move (at most once a day, see `MoveCheck`) and asks "Did you
/// move?" if the phone has been away from the saved area.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMove());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkMove();
  }

  Future<void> _checkMove() async {
    final services = AppServices.of(context);
    if (!services.checkMoveOnLaunch || _checking) return;
    _checking = true;
    try {
      final ask = await services.moveCheck.shouldAsk();
      // Only over the tabs themselves, not over a screen the user opened.
      if (ask && mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
        await askIfMoved(context);
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      // IndexedStack keeps each tab's state (scroll, search text) when switching.
      body: IndexedStack(
        index: _index,
        children: [
          TodayScreen(onOpenSearch: () => setState(() => _index = 1)),
          const SearchScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l10n.tabSearch,
          ),
        ],
      ),
    );
  }
}
