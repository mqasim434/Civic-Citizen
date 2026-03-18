import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import 'dashboard_view.dart';
import '../../profile/views/profile_view.dart';
import '../views/map_placeholder_view.dart';

/// Main shell with bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.map_rounded, label: 'Map'),
    _TabItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardView(),
          MapPlaceholderView(),
          ProfileView(),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => navigatorKey.currentState?.pushNamed(
                AppConstants.routeCreatePost,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
