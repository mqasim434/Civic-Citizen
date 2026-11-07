import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_atmosphere.dart';
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
    final user = await context.read<AuthController>().signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
    if (!mounted) return;
    if (user != null) {
      navigatorKey.currentState?.pushReplacementNamed(
        AppConstants.routeKyc,
        arguments: {
          'uid': user.uid,
          'displayName': user.displayName ?? _nameController.text.trim(),
          'email': user.email ?? _emailController.text.trim(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppAtmosphere(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 18),
                  Text(
                    'Create account',
                    style: theme.textTheme.displaySmall,
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Join your neighbors to share lost items, resources, and help.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hint: 'Your name',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your name';
                      return null;
                    },
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05, end: 0),
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
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your email';
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint:
                        'At least ${AppConstants.minPasswordLength} characters',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a password';
                      if (v.length < AppConstants.minPasswordLength) {
                        return 'Use at least ${AppConstants.minPasswordLength} characters';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.05, end: 0),
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
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                  ).animate().fadeIn(delay: 460.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
