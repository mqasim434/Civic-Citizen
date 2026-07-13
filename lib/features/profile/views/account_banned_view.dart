import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/profile_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Shown when an admin has banned the signed-in user.
class AccountBannedView extends StatelessWidget {
  const AccountBannedView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: context.read<ProfileService>().watchProfile(user.uid),
      builder: (context, snap) {
        final profile = snap.data;
        if (!ProfileService.isBanned(profile)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              navigatorKey.currentState?.pushReplacementNamed(
                AppConstants.routeHome,
              );
            }
          });
        }

        final reason = profile?['banReason'] as String?;

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Account suspended'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 72,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your account has been suspended',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'An administrator has restricted access to Civic Citizen. '
                    'You cannot browse posts or create new listings while suspended.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (reason != null && reason.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(reason.trim(), style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        navigatorKey.currentState?.pushNamedAndRemoveUntil(
                          AppConstants.routeLogin,
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
