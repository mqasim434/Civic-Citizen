import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/post_auth_navigation.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_atmosphere.dart';
import '../../../core/utils/firestore_retry.dart';
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
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
      ),
    );
    if (!mounted || result == null) return;
    messenger.showSnackBar(SnackBar(content: Text(result)));
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
                  const SizedBox(height: 48),
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
                    'Welcome back',
                    style: theme.textTheme.displaySmall,
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue to your neighborhood feed.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 36),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
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
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05, end: 0),
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
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      return null;
                    },
                  ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.05, end: 0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('Forgot password?'),
                    ),
                  ).animate().fadeIn(delay: 320.ms),
                  const SizedBox(height: 8),
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
                  ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                  ).animate().fadeIn(delay: 420.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns its own controllers/loading so Provider rebuilds don't race dialog dispose.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _loading = true);

    final auth = context.read<AuthController>();
    auth.clearError();
    await auth.sendPasswordReset(_emailController.text);

    if (!mounted) return;

    final error = auth.error;
    if (error != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.of(context).pop(
      'Password reset email sent. Check your inbox.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Reset password'),
      content: Form(
        key: _formKey,
        child: AppTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          enabled: !_loading,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your email';
            if (!v.contains('@') || !v.contains('.')) {
              return 'Enter a valid email';
            }
            return null;
          },
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : const Text('Send link'),
        ),
      ],
    );
  }
}
