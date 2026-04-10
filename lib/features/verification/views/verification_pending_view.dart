import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../kyc/models/kyc_status.dart';
import '../../kyc/services/kyc_service.dart';

/// Shown after KYC submit until an admin verifies the account.
class VerificationPendingView extends StatelessWidget {
  const VerificationPendingView({super.key});

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
        if (status == KycStatus.rejected.name) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeVerificationRejected);
            }
          });
        }

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
                    Icons.verified_user_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Profile under verification',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thank you for submitting your documents. Your profile is being reviewed by our team. '
                    'This may take up to 24 hours.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'When your account is verified, this screen updates automatically — no extra setup needed. '
                    'Keep the app installed and check back, or leave this screen open.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
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
