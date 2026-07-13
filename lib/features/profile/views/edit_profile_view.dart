import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/profile_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/services/auth_service.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _saving = true);
    final authService = context.read<AuthService>();
    final profileService = context.read<ProfileService>();
    try {
      final name = _nameController.text.trim();
      await authService.updateDisplayName(name);
      await profileService.updateDisplayName(
            uid: user.uid,
            displayName: name,
          );
      await auth.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update how your name appears on posts and in the app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameController,
                label: 'Display name',
                hint: 'Your name',
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter a display name';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                onSubmitted: (_) => _save(),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Email',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  user!.email!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Save changes',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
