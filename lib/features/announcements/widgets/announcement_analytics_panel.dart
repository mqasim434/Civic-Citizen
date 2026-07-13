import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/announcement_poll.dart';
import '../../../core/models/app_announcement.dart';
import '../../../core/services/announcement_service.dart';

/// Admin view of helpful feedback and poll results for one broadcast.
class AnnouncementAnalyticsPanel extends StatelessWidget {
  const AnnouncementAnalyticsPanel({super.key, required this.announcement});

  final AppAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.read<AnnouncementService>();

    return FutureBuilder<AnnouncementAudienceStats>(
      future: service.getAudienceStats(announcement.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Text(
            'Could not load analytics: ${snap.error}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          );
        }

        final stats = snap.data ?? const AnnouncementAudienceStats();
        if (stats.totalResponses == 0 &&
            !announcement.hasPoll &&
            stats.helpfulYes == 0 &&
            stats.helpfulNo == 0) {
          return Text(
            'No audience responses yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Audience feedback',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatChip(
                  icon: Icons.thumb_up_outlined,
                  label: '${stats.helpfulYes} helpful',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.thumb_down_outlined,
                  label: '${stats.helpfulNo} not helpful',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.visibility_outlined,
                  label: '${stats.totalResponses} responses',
                ),
              ],
            ),
            if (announcement.hasPoll) ...[
              const SizedBox(height: 16),
              Text(
                'Poll results',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                announcement.pollQuestion!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              ...announcement.pollOptions.map((option) {
                final votes = stats.pollVotesByOptionId[option.id] ?? 0;
                final total = stats.totalPollVotes;
                final pct = total > 0 ? (votes / total * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(option.text)),
                          Text(
                            '$votes ($pct%)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: total > 0 ? votes / total : 0,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }),
              Text(
                '${stats.totalPollVotes} total votes',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
