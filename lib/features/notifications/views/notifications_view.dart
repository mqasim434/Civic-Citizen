import '../../../core/models/app_notification.dart';
import '../../../core/navigation/notification_navigation.dart';
import '../../../core/services/notification_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  String _filter = 'All';

  /// Ids of notifications picked with a long press.
  final Set<String> _selected = {};

  /// Notifications currently shown (after the filter), for "select all".
  List<AppNotification> _visible = const [];

  bool get _selecting => _selected.isNotEmpty;

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  Future<void> _setRead(String uid, bool read) async {
    final ids = _selected.toList();
    _clearSelection();
    await context
        .read<NotificationService>()
        .setReadMany(uid, ids, read: read);
  }

  Future<void> _deleteSelected(String uid) async {
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          count == 1 ? 'Delete notification?' : 'Delete $count notifications?',
        ),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ids = _selected.toList();
    _clearSelection();
    try {
      await context.read<NotificationService>().deleteMany(uid, ids);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete notifications.')),
      );
    }
  }

  PreferredSizeWidget _appBar(String uid, NotificationService service) {
    if (!_selecting) {
      return AppBar(
        flexibleSpace: const WaveHeaderBackground(),
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: () => service.markAllRead(uid),
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      );
    }
    final selectedItems =
        _visible.where((n) => _selected.contains(n.id)).toList();
    final anyUnread = selectedItems.any((n) => !n.read);
    final allSelected =
        _visible.isNotEmpty && _visible.every((n) => _selected.contains(n.id));
    return AppBar(
      flexibleSpace: const WaveHeaderBackground(),
      leading: IconButton(
        tooltip: 'Cancel',
        icon: const Icon(Icons.close_rounded),
        onPressed: _clearSelection,
      ),
      title: Text('${_selected.length} selected'),
      actions: [
        IconButton(
          tooltip: allSelected ? 'Deselect all' : 'Select all',
          icon: Icon(
            allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
          ),
          onPressed: () => setState(() {
            if (allSelected) {
              _selected.clear();
            } else {
              _selected.addAll(_visible.map((n) => n.id));
            }
          }),
        ),
        IconButton(
          tooltip: anyUnread ? 'Mark as read' : 'Mark as unread',
          icon: Icon(
            anyUnread
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
          ),
          onPressed: () => _setRead(uid, anyUnread),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _deleteSelected(uid),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final service = context.read<NotificationService>();

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
      appBar: _appBar(user.uid, service),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                for (final label in const ['All', 'Important', 'Updates'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filter == label,
                      onSelected: (_) => setState(() {
                        _filter = label;
                        _selected.clear();
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
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
          final items = (snap.data ?? []).where((n) {
            if (_filter == 'Important') {
              return n.type == AppNotificationType.accountBanned ||
                  n.type == AppNotificationType.kycRejected ||
                  n.type == AppNotificationType.postFlagged ||
                  n.type == AppNotificationType.claimCreated;
            }
            if (_filter == 'Updates') {
              return n.type == AppNotificationType.eventPublished ||
                  n.type == AppNotificationType.postCreated ||
                  n.type == AppNotificationType.kycApproved;
            }
            return true;
          }).toList();
          _visible = items;
          // Drop selections for notifications that no longer exist.
          final ids = items.map((n) => n.id).toSet();
          if (_selected.any((id) => !ids.contains(id))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selected.retainAll(ids));
            });
          }
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = items[i];
              final isSelected = _selected.contains(n.id);
              return ListTile(
                selected: isSelected,
                selectedTileColor:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: isSelected
                    ? CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.check_rounded,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : CircleAvatar(
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
                    color: theme.colorScheme.onSurface,
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
                onLongPress: () => _toggle(n.id),
                onTap: () async {
                  if (_selecting) {
                    _toggle(n.id);
                    return;
                  }
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
          ),
        ],
      ),
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
      case AppNotificationType.postCreated:
        return Icons.post_add_rounded;
      case AppNotificationType.contractCreated:
      case AppNotificationType.contractLenderSigned:
      case AppNotificationType.contractBorrowerSigned:
      case AppNotificationType.contractCompleted:
        return Icons.handshake_outlined;
      case AppNotificationType.claimCreated:
      case AppNotificationType.claimReadyForHandshake:
      case AppNotificationType.claimCompleted:
        return Icons.qr_code_scanner_rounded;
      case AppNotificationType.contactRequested:
        return Icons.mail_outline_rounded;
      case AppNotificationType.contactAccepted:
        return Icons.check_circle_outline;
      case AppNotificationType.contactDeclined:
        return Icons.person_off_outlined;
      case AppNotificationType.eventPublished:
        return Icons.event_available_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    return dt.toLocal().toString().split('.').first;
  }
}
