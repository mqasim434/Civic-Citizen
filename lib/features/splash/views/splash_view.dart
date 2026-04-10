import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/post_auth_navigation.dart';
import '../../../core/routes/app_router.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.people_alt_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              const Spacer(flex: 2),
              SizedBox(
                height: 4,
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(delay: 600.ms)
                  .then()
                  .fadeOut(duration: 800.ms),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
