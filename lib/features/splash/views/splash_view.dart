import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/post_auth_navigation.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/firestore_retry.dart';
import '../../admin/services/admin_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../kyc/services/kyc_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future<void>.delayed(
      const Duration(seconds: AppConstants.splashDurationSeconds),
    );
    if (!mounted) return;
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeLogin);
      return;
    }
    final user = auth.user!;
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
      final message = isFirestoreUnavailable(e)
          ? 'Server temporarily unavailable. Check your connection and try again.'
          : 'Could not load your account. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash_background.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 72),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect  •  Help  •  Build Community',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.inkMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: Text(
                    'Together for\na Better Community',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ivory,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
