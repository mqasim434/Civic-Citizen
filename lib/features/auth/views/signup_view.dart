import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.read<AuthController>().clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context.read<AuthController>().signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
    if (!mounted) return;
    if (success) {
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeHome);
    }
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
                  const SizedBox(height: 32),
                  Icon(
                    Icons.person_add_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  )
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 24),
                  Text(
                    'Create account',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Join ${AppConstants.appName} to connect with your community',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hint: 'Your name',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your name';
                      return null;
                    },
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'At least ${AppConstants.minPasswordLength} characters',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a password';
                      if (v.length < AppConstants.minPasswordLength) {
                        return 'Use at least ${AppConstants.minPasswordLength} characters';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05, end: 0),
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
                      label: 'Sign up',
                      onPressed: _submit,
                      loading: auth.isLoading,
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          navigatorKey.currentState?.pushReplacementNamed(
                            AppConstants.routeLogin,
                          );
                        },
                        child: const Text('Sign in'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
