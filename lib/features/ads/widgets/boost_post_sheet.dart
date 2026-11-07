import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/models/post_model.dart';
import '../services/ad_service.dart';

Future<void> showBoostPostDialog(BuildContext context, PostModel post) async {
  final user = context.read<AuthController>().user;
  if (user == null) return;
  final ads = context.read<AdService>();
  final cost = await ads.getAdPointsCost();
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Boost this post?'),
      content: Text(
        'Sponsoring "${post.title}" costs $cost Civic Points and keeps it '
        'marked as Sponsored for ${AppConstants.adDurationDays} days.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Boost'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ads.boostPost(
      postId: post.id,
      authorId: user.uid,
      authorName: user.displayName ?? user.email ?? 'Citizen',
      title: post.title,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post is now sponsored')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
    );
  }
}

void showPostInsights(BuildContext context, PostModel post) {
  final until = post.sponsoredUntil;
  final active = post.isSponsored;
  final untilLabel = until == null
      ? 'Not scheduled'
      : '${until.day}/${until.month}/${until.year}';

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ad insights', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              post.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _Stat(label: 'People reached', value: '${post.viewCount}'),
            _Stat(label: 'Likes', value: '${post.likeCount}'),
            _Stat(label: 'Comments', value: '${post.commentCount}'),
            const SizedBox(height: 8),
            Text(
              active
                  ? 'Sponsored until $untilLabel'
                  : 'Sponsorship ended $untilLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
