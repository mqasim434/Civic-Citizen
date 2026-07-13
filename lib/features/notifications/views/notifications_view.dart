import '../../../core/models/app_notification.dart';
import '../../../core/navigation/notification_navigation.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final service = context.read<NotificationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => service.markAllRead(user.uid),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: service.watchNotifications(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load notifications.\n'
                  'Deploy Firestore rules (see docs/NOTIFICATIONS_SETUP.md).\n\n'
                  '${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = items[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.read
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    _iconFor(n.type),
                    color: n.read
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(n.body),
                    if (n.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(n.createdAt!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
                isThreeLine: true,
                onTap: () async {
                  if (!n.read) {
                    await service.markRead(user.uid, n.id);
                  }
                  if (!context.mounted) return;
                  await navigateFromNotification(
                    n,
                    postService: context.read<PostService>(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.kycSubmittedAdmin:
        return Icons.verified_user_outlined;
      case AppNotificationType.kycApproved:
        return Icons.check_circle_outline;
      case AppNotificationType.kycRejected:
        return Icons.cancel_outlined;
      case AppNotificationType.accountBanned:
        return Icons.block;
      case AppNotificationType.postFlagged:
        return Icons.flag_outlined;
      case AppNotificationType.contractCreated:
      case AppNotificationType.contractLenderSigned:
      case AppNotificationType.contractBorrowerSigned:
      case AppNotificationType.contractCompleted:
        return Icons.handshake_outlined;
      case AppNotificationType.claimCreated:
      case AppNotificationType.claimReadyForHandshake:
      case AppNotificationType.claimCompleted:
        return Icons.qr_code_scanner_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    return dt.toLocal().toString().split('.').first;
  }
}
