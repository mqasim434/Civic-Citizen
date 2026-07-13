import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/public_trust_profile.dart';
import '../services/trust_profile_service.dart';

/// Read-only trust card for a community member.
class TrustCardWidget extends StatelessWidget {
  const TrustCardWidget({
    super.key,
    required this.userId,
    this.displayNameFallback,
    this.compact = false,
  });

  final String userId;
  final String? displayNameFallback;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.read<TrustProfileService>();

    return StreamBuilder<PublicTrustProfile?>(
      stream: service.watchProfile(userId),
      builder: (context, snap) {
        final profile = snap.data;
        final name = profile?.displayName ??
            displayNameFallback ??
            'Community member';
        final verified = profile?.isVerified ?? false;
        final exchanges = profile?.completedExchanges ?? 0;
        final recoveries = profile?.completedRecoveries ?? 0;
        final memberSince = profile?.memberSince;

        return Container(
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: compact ? 18 : 22,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (verified)
                              _Badge(
                                icon: Icons.verified_rounded,
                                label: 'Verified',
                                color: theme.colorScheme.primary,
                              )
                            else
                              _Badge(
                                icon: Icons.hourglass_top_rounded,
                                label: 'Pending verification',
                                color: theme.colorScheme.outline,
                              ),
                            if (exchanges > 0)
                              _Badge(
                                icon: Icons.handshake_outlined,
                                label:
                                    '$exchanges exchange${exchanges == 1 ? '' : 's'}',
                                color: theme.colorScheme.tertiary,
                              ),
                            if (recoveries > 0)
                              _Badge(
                                icon: Icons.qr_code_scanner_rounded,
                                label:
                                    '$recoveries recover${recoveries == 1 ? 'y' : 'ies'}',
                                color: theme.colorScheme.secondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!compact && memberSince != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Member since ${memberSince.toLocal().toString().split(' ').first}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  'Contact is shared only after the author approves your request.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
