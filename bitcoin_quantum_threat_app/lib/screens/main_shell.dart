import 'package:flutter/material.dart';

import 'glossary_screen.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'quick_check_screen.dart';
import 'simulator_screen.dart';
import 'timeline_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onOpenSimulator: () => _go(1),
            onOpenQuick: () => _go(2),
          ),
          const SimulatorScreen(),
          const QuickCheckScreen(),
          const NewsScreen(),
          const TimelineScreen(),
          const GlossaryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.area_chart_outlined),
            selectedIcon: Icon(Icons.area_chart),
            label: 'Simulator',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Quick',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Glossary',
          ),
        ],
      ),
    );
  }
}
