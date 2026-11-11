import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  Future<void> _mail(String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {'subject': subject},
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const WaveHeaderBackground(),
        bottom: const WaveHeaderSpacer(),
        title: const Text('Help & Support'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.headset_mic_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'How can we help you today?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _HelpTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Problem',
            subtitle: 'Report bugs or technical issues.',
            onTap: () => _mail('Report a Problem'),
          ),
          _HelpTile(
            icon: Icons.person_outline_rounded,
            title: 'Account Issues',
            subtitle: 'Login, profile and account problems.',
            onTap: () => _mail('Account Issues'),
          ),
          _HelpTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Feedback & Suggestions',
            subtitle: 'Share your ideas with us.',
            onTap: () => _mail('Feedback & Suggestions'),
          ),
          const SizedBox(height: 28),
          Icon(
            Icons.support_agent_rounded,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _mail('Civic Citizen support'),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Contact Support via Email'),
          ),
          const SizedBox(height: 10),
          SelectableText(
            AppConstants.supportEmail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.colors(context).inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: CircleAvatar(
            backgroundColor: AppTheme.colors(context).sage,
            child: Icon(icon, color: AppTheme.colors(context).olive),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
