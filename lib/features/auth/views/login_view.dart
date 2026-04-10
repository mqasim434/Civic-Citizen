import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/post_auth_navigation.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../admin/services/admin_service.dart';
import '../../kyc/services/kyc_service.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.read<AuthController>().clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context.read<AuthController>().signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      final auth = context.read<AuthController>();
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.login_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  )
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome back',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue to ${AppConstants.appName}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 40),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      return null;
                    },
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 12),
                  Consumer<AuthController>(
                    builder: (_, auth, __) {
                      if (auth.error == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          auth.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ).animate().fadeIn().shake();
                    },
                  ),
                  Consumer<AuthController>(
                    builder: (_, auth, __) => AppButton(
                      label: 'Sign in',
                      onPressed: _submit,
                      loading: auth.isLoading,
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          navigatorKey.currentState?.pushReplacementNamed(
                            AppConstants.routeSignup,
                          );
                        },
                        child: const Text('Sign up'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
