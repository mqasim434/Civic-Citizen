import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../kyc/models/kyc_status.dart';
import '../../kyc/services/kyc_service.dart';

/// Shown when admin declined verification.
class VerificationRejectedView extends StatelessWidget {
  const VerificationRejectedView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: context.read<KycService>().watchUserProfile(user.uid),
      builder: (context, snap) {
        final profile = snap.data;
        final status = profile?['verificationStatus'] as String?;
        if (status == KycStatus.verified.name) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeHome);
            }
          });
        }
        if (status == KycStatus.pending.name) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeVerificationPending);
            }
          });
        }

        final reason = profile?['rejectionReason'] as String?;

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Verification'),
              actions: [
                TextButton(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      navigatorKey.currentState?.pushNamedAndRemoveUntil(
                        AppConstants.routeLogin,
                        (_) => false,
                      );
                    }
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.cancel_outlined,
                    size: 72,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verification not approved',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We could not verify your profile at this time. See below for any reason we shared.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reason,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton.icon(
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
