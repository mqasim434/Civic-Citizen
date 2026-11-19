import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/post_auth_navigation.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_atmosphere.dart';
import '../../../core/utils/firestore_retry.dart';
import '../../../shared/widgets/app_button.dart';
import '../../admin/services/admin_service.dart';
import '../../kyc/services/kyc_service.dart';
import '../controllers/auth_controller.dart';

/// Holds a new account until Firebase confirms the inbox is real.
class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  bool _checking = false;
  bool _resending = false;

  Future<void> _continue() async {
    final auth = context.read<AuthController>();
    setState(() => _checking = true);
    await auth.refreshUser();
    if (!mounted) return;
    final user = auth.user;
    if (user == null) {
      setState(() => _checking = false);
      return;
    }
    if (user.needsEmailVerification) {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not verified yet. Open the link we sent, then try again.',
          ),
        ),
      );
      return;
    }
    try {
      final dest = await resolvePostAuthDestination(
        uid: user.uid,
        kycService: context.read<KycService>(),
        adminService: context.read<AdminService>(),
      );
      if (!mounted) return;
      pushDestination(
        dest,
        uid: user.uid,
        displayName: user.displayName ?? '',
        email: user.email ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      final message = isFirestoreUnavailable(e)
          ? 'Server temporarily unavailable. Check your connection and try again.'
          : 'Could not load your account. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    setState(() => _resending = true);
    await auth.sendEmailVerification();
    if (!mounted) return;
    setState(() => _resending = false);
    final error = auth.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Verification email sent. Check your inbox and spam folder.',
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthController>();
    await auth.signOut();
    if (!mounted) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppConstants.routeLogin,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.watch<AuthController>().user?.email ?? 'your email';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppAtmosphere(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check your email',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to $email. Open it to confirm this inbox, then continue.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    label: "I've verified my email",
                    onPressed: _checking ? null : _continue,
                    loading: _checking,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_resending ? 'Sending…' : 'Resend email'),
                  ),
                  TextButton(
                    onPressed: _signOut,
                    child: const Text('Sign out'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
