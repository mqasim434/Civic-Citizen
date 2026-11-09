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

String _remainingLabel(int ms) {
  final d = Duration(milliseconds: ms);
  if (d.inDays >= 1) {
    return d.inDays == 1 ? '1 day left' : '${d.inDays} days left';
  }
  if (d.inHours >= 1) {
    return d.inHours == 1 ? '1 hour left' : '${d.inHours} hours left';
  }
  return 'Less than an hour left';
}

Future<void> _runAdAction(
  BuildContext context,
  Future<void> Function() action,
  String doneMessage,
) async {
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).pop();
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
    );
  }
}

Future<bool> _confirmStop(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Stop this ad?'),
      content: const Text(
        'The ad ends now and stops showing as Sponsored. '
        'Points already spent are not refunded.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep running'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Stop ad'),
        ),
      ],
    ),
  );
  return ok == true;
}

void showPostInsights(BuildContext context, PostModel post) {
  final until = post.sponsoredUntil;
  final active = post.isSponsored;
  final paused = post.isSponsorPaused;
  final untilLabel = until == null
      ? 'Not scheduled'
      : '${until.day}/${until.month}/${until.year}';
  final uid = context.read<AuthController>().user?.uid;
  final canManage = uid != null && uid == post.authorId && (active || paused);
  final ads = context.read<AdService>();

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
              paused
                  ? 'Paused · ${_remainingLabel(post.sponsorPausedRemainingMs!)}'
                  : active
                      ? 'Sponsored until $untilLabel'
                      : 'Sponsorship ended $untilLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: paused
                        ? FilledButton.icon(
                            onPressed: () => _runAdAction(
                              ctx,
                              () => ads.resumeSponsorship(
                                postId: post.id,
                                authorId: uid,
                              ),
                              'Ad resumed',
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Resume'),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _runAdAction(
                              ctx,
                              () => ads.pauseSponsorship(
                                postId: post.id,
                                authorId: uid,
                              ),
                              'Ad paused. Remaining time is saved.',
                            ),
                            icon: const Icon(Icons.pause_rounded),
                            label: const Text('Pause'),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!await _confirmStop(ctx)) return;
                        if (!ctx.mounted) return;
                        await _runAdAction(
                          ctx,
                          () => ads.stopSponsorship(
                            postId: post.id,
                            authorId: uid,
                          ),
                          'Ad stopped',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop ad'),
                    ),
                  ),
                ],
              ),
            ],
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
