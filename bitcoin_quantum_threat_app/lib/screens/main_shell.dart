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
            onOpenSimulator: () => _go(2),
            onOpenQuick: () => _go(1),
          ),
          const QuickCheckScreen(),
          const SimulatorScreen(),
          const NewsScreen(),
          const TimelineScreen(),
          const GlossaryScreen(),
        ],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          const kDestinations = 6;
          const longSimulator = 'Full risk simulator';
          final labelStyle = NavigationBarTheme.of(context).labelTextStyle?.resolve(
                    <WidgetState>{WidgetState.selected},
                  ) ??
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
          final tp = TextPainter(
            text: TextSpan(text: longSimulator, style: labelStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          final slotW = constraints.maxWidth / kDestinations;
          // Tight columns: if the long label is wider than a slot, use the short form.
          const slotPaddingBudget = 10.0;
          final simulatorLabel = tp.width <= slotW - slotPaddingBudget ? longSimulator : 'Simulator';

          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt),
                label: 'Quick',
              ),
              NavigationDestination(
                icon: const Icon(Icons.area_chart_outlined),
                selectedIcon: const Icon(Icons.area_chart),
                label: simulatorLabel,
              ),
              const NavigationDestination(
                icon: Icon(Icons.newspaper_outlined),
                selectedIcon: Icon(Icons.newspaper),
                label: 'News',
              ),
              const NavigationDestination(
                icon: Icon(Icons.timeline_outlined),
                selectedIcon: Icon(Icons.timeline),
                label: 'Timeline',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Glossary',
              ),
            ],
          );
        },
      ),
    );
  }
}
