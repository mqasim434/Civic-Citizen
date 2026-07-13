import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/app_announcement.dart';
import '../../../core/routes/app_router.dart';
import 'broadcast_poll_card.dart';

Future<void> showAnnouncementDialog(
  BuildContext context,
  AppAnnouncement announcement,
) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.campaign_rounded,
        color: theme.colorScheme.primary,
        size: 32,
      ),
      title: Text(announcement.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (announcement.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  announcement.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.outline,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              announcement.body,
              style: theme.textTheme.bodyLarge,
            ),
            if (announcement.hasPoll) ...[
              const SizedBox(height: 20),
              BroadcastPollCard(announcement: announcement, compact: true),
            ],
          ],
        ),
      ),
      actions: [
        if (announcement.hasPoll)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              navigatorKey.currentState?.pushNamed(
                AppConstants.routeBroadcastDetail,
                arguments: announcement,
              );
            },
            child: const Text('Open full broadcast'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
