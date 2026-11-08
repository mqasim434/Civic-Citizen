import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/services/auth_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeCtrl = context.watch<ThemeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              value: themeCtrl.isDark && !themeCtrl.isSystem,
              onChanged: (v) => themeCtrl.setMode(
                v ? ThemeMode.dark : ThemeMode.light,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Account', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => navigatorKey.currentState?.pushNamed(
                    AppConstants.routeEditProfile,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy & Security'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _PrivacySecurityPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('App', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.language_rounded),
                  title: Text('Language'),
                  trailing: Text('English'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About App'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: '1.0.0',
                      children: const [
                        Text('Connect. Help. Build Community.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_auto_rounded),
            title: const Text('Use system theme'),
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

Future<void> _showChangePasswordDialog(BuildContext context) async {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var saving = false;
  var obscure = true;

  String messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Could not change password.';
    }
  }

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Change password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: current,
                      label: 'Current password',
                      obscureText: obscure,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your current password' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: next,
                      label: 'New password',
                      obscureText: obscure,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: confirm,
                      label: 'Confirm new password',
                      obscureText: obscure,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          v != next.text ? 'Passwords do not match' : null,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        child: Text(obscure ? 'Show passwords' : 'Hide passwords'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => saving = true);
                          try {
                            await dialogContext.read<AuthService>().changePassword(
                                  currentPassword: current.text,
                                  newPassword: next.text,
                                );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password updated')),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => saving = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(messageFor(e))),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => saving = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$e'.replaceFirst('Exception: ', ''),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    current.dispose();
    next.dispose();
    confirm.dispose();
  }
}

class _PrivacySecurityPage extends StatelessWidget {
  const _PrivacySecurityPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.watch<AuthController>().user?.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your account',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            email == null || email.isEmpty
                ? 'You are signed in.'
                : 'Signed in as $email.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showChangePasswordDialog(context),
            ),
          ),
          const SizedBox(height: 24),
          Text('What other members can see', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Your name, profile photo, and posts are visible to signed-in members. '
            'Your email and password are not shown on posts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text('Location', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Home and Nearby use your location to show posts around you. '
            'You can change the place from the Home pin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
