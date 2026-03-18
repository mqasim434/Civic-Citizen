import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../controllers/kyc_controller.dart';

class KycView extends StatefulWidget {
  const KycView({
    super.key,
    required this.uid,
    required this.displayName,
    required this.email,
  });

  final String uid;
  final String displayName;
  final String email;

  @override
  State<KycView> createState() => _KycViewState();
}

class _KycViewState extends State<KycView> {
  int _step = 0;

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
          child: Column(
            children: [
              _buildProgress(theme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _step == 0 ? _buildCnicStep(theme) : _buildSelfieStep(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(theme, 0, 'CNIC'),
          Expanded(child: Container(height: 2, color: theme.colorScheme.primary.withValues(alpha: 0.3))),
          _buildStepIndicator(theme, 1, 'Selfie'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme, int step, String label) {
    final isActive = _step == step;
    final isDone = _step > step;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isDone || isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.2),
          child: isDone
              ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
              : Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: isActive ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCnicStep(ThemeData theme) {
    return Consumer<KycController>(
      builder: (_, kyc, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.badge_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 24),
            Text(
              'Verify your identity',
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of your CNIC (National ID card). Ensure all details are visible.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 32),
            if (kyc.cnicImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  kyc.cnicImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Retake',
                      outlined: true,
                      onPressed: () {
                        kyc.clearError();
                        kyc.pickCnic(fromCamera: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Continue',
                      onPressed: () => setState(() => _step = 1),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildCaptureOption(
                      theme: theme,
                      icon: Icons.camera_alt_rounded,
                      label: 'Take photo',
                      onTap: () => kyc.pickCnic(fromCamera: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCaptureOption(
                      theme: theme,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => kyc.pickCnic(fromCamera: false),
                    ),
                  ),
                ],
              ),
            ],
            if (kyc.error != null) ...[
              const SizedBox(height: 16),
              Text(
                kyc.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ).animate().fadeIn().shake(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCaptureOption({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelfieStep(ThemeData theme) {
    return Consumer<KycController>(
      builder: (_, kyc, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(
              Icons.face_retouching_natural_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 24),
            Text(
              'Live selfie',
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              'Take a selfie using your camera. Gallery upload is disabled for security. Your face must be clearly visible.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 32),
            if (kyc.selfieImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  kyc.selfieImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Back',
                      outlined: true,
                      onPressed: () => setState(() => _step = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Retake',
                      outlined: true,
                      onPressed: () {
                        kyc.clearError();
                        kyc.captureSelfie();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Submit',
                      loading: kyc.isLoading,
                      onPressed: _submitKyc,
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildCaptureOption(
                theme: theme,
                icon: Icons.camera_front_rounded,
                label: 'Take selfie',
                onTap: () => kyc.captureSelfie(),
              ),
            ],
            if (kyc.error != null) ...[
              const SizedBox(height: 16),
              Text(
                kyc.error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ).animate().fadeIn().shake(),
            ],
          ],
        );
      },
    );
  }

  Future<void> _submitKyc() async {
    final kyc = context.read<KycController>();
    kyc.clearError();
    final success = await kyc.submitKyc(
      uid: widget.uid,
      displayName: widget.displayName,
      email: widget.email,
    );
    if (!mounted) return;
    if (success) {
      kyc.clearImages();
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeHome);
    }
  }
}
