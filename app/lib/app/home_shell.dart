import 'package:flutter/material.dart';

import '../features/search/search_screen.dart';
import '../features/today/today_screen.dart';
import '../l10n/app_localizations.dart';

/// Bottom navigation between the two main tabs. Settings is pushed on top
/// from the gear in each tab's top bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      // IndexedStack keeps each tab's state (scroll, search text) when switching.
      body: IndexedStack(
        index: _index,
        children: const [TodayScreen(), SearchScreen()],
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
