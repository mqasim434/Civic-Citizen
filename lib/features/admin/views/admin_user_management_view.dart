import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/admin_service.dart';

class AdminUserManagementView extends StatefulWidget {
  const AdminUserManagementView({super.key});

  @override
  State<AdminUserManagementView> createState() => _AdminUserManagementViewState();
}

class _AdminUserManagementViewState extends State<AdminUserManagementView> {
  final Set<String> _busyUserIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<AdminService>().watchUsers(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading users: ${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 56, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text('No users found', style: theme.textTheme.titleMedium),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data();
            final uid = doc.id;
            final name = (d['displayName'] as String?)?.trim();
            final email = (d['email'] as String?)?.trim();
            final banned = d['isBanned'] == true;
            final busy = _busyUserIds.contains(uid);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (name != null && name.isNotEmpty) ? name[0].toUpperCase() : '?',
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(name == null || name.isEmpty ? 'Unnamed user' : name)),
                    if (banned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BANNED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(email == null || email.isEmpty ? 'No email' : email),
                trailing: busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PopupMenuButton<String>(
                        tooltip: 'Manage user',
                        onSelected: (value) async {
                          if (value == 'ban') {
                            await _setBanned(uid, true);
                            return;
                          }
                          if (value == 'unban') {
                            await _setBanned(uid, false);
                            return;
                          }
                          if (value == 'delete') {
                            await _deleteUser(uid, name ?? email ?? 'user');
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: banned ? 'unban' : 'ban',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                banned
                                    ? Icons.lock_open_rounded
                                    : Icons.block_flipped,
                              ),
                              title: Text(banned ? 'Unban user' : 'Ban user'),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.delete_forever_rounded),
                              title: Text('Delete profile'),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _setBanned(String uid, bool banned) async {
    String? reason;
    if (banned) {
      reason = await _askReason();
      if (!mounted) return;
      if (reason == null) return;
    }
    setState(() => _busyUserIds.add(uid));
    String message;
    var success = true;
    try {
      await context.read<AdminService>().setUserBanned(
            uid,
            banned: banned,
            reason: reason?.trim().isEmpty ?? true ? null : reason?.trim(),
          );
      message = banned ? 'User banned.' : 'User unbanned.';
    } catch (e) {
      success = false;
      message = 'Failed to update user: $e';
    }
    if (!mounted) return;
    setState(() => _busyUserIds.remove(uid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? null : Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  Future<void> _deleteUser(String uid, String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile'),
        content: Text(
          'Delete "$label" profile and all authored posts? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busyUserIds.add(uid));
    String message;
    var success = true;
    try {
      await context.read<AdminService>().deleteUserProfile(uid);
      message = 'User profile deleted.';
    } catch (e) {
      success = false;
      message = 'Failed to delete profile: $e';
    }
    if (!mounted) return;
    setState(() => _busyUserIds.remove(uid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? null : Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ban user'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Reason for ban',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
