import 'package:flutter/material.dart';

import '../utils/haptics.dart';
import '../widgets/glass_bottom_nav_bar.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'new_month_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: GlassBottomNavBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          GlassNavDestination(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: 'Months',
          ),
          GlassNavDestination(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights,
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
