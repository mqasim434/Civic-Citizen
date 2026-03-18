import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCtrl = context.watch<ThemeController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: Icon(
              themeCtrl.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Dark mode'),
            subtitle: Text(
              themeCtrl.isSystem
                  ? 'Using system setting'
                  : themeCtrl.isDark
                      ? 'On'
                      : 'Off',
            ),
            value: themeCtrl.isDark,
            onChanged: themeCtrl.isSystem
                ? null
                : (v) => themeCtrl.setMode(v ? ThemeMode.dark : ThemeMode.light),
          ),
          SwitchListTile(
            secondary: Icon(Icons.brightness_auto_rounded, color: theme.colorScheme.primary),
            title: const Text('Use system theme'),
            subtitle: const Text('Follow device light/dark setting'),
            value: themeCtrl.isSystem,
            onChanged: (v) {
              themeCtrl.setMode(v ? ThemeMode.system : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }
}
