import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/app_announcement.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/announcement_service.dart';
import '../../auth/controllers/auth_controller.dart';

class BroadcastsView extends StatelessWidget {
  const BroadcastsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    final service = context.read<AnnouncementService>();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Community broadcasts')),
      body: StreamBuilder<Set<String>>(
        stream: service.watchSeenAnnouncementIds(user.uid),
        builder: (context, seenSnap) {
          final seenIds = seenSnap.data ?? {};
          return StreamBuilder<List<AppAnnouncement>>(
            stream: service.watchActiveAnnouncements(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snap.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No broadcasts right now',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Official announcements from administrators will appear here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final seen = seenIds.contains(item.id);
                  return _BroadcastListTile(
                    announcement: item,
                    seen: seen,
                    onTap: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeBroadcastDetail,
                      arguments: item,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BroadcastListTile extends StatelessWidget {
  const _BroadcastListTile({
    required this.announcement,
    required this.seen,
    required this.onTap,
  });

  final AppAnnouncement announcement;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.campaign_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!seen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'New',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.75),
                      ),
                    ),
                    if (announcement.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(announcement.createdAt!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
