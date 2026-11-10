import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/shell_tab.dart';
import '../../../core/navigation/tab_reselect.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../services/admin_service.dart';
import '../ui/admin_ui.dart';
import '../widgets/legal_export_dialog.dart';

enum _UserFilter { all, active, verified, pending, banned }

extension on _UserFilter {
  String get label {
    switch (this) {
      case _UserFilter.all:
        return 'All users';
      case _UserFilter.active:
        return 'Active';
      case _UserFilter.verified:
        return 'Verified';
      case _UserFilter.pending:
        return 'Pending verification';
      case _UserFilter.banned:
        return 'Banned';
    }
  }

  bool matches(Map<String, dynamic> d) {
    final banned = d['isBanned'] == true;
    switch (this) {
      case _UserFilter.all:
        return true;
      case _UserFilter.active:
        return !banned;
      case _UserFilter.verified:
        return d['verificationStatus'] == 'verified';
      case _UserFilter.pending:
        return d['verificationStatus'] == 'pending';
      case _UserFilter.banned:
        return banned;
    }
  }
}

class AdminUserManagementView extends StatefulWidget {
  const AdminUserManagementView({super.key});

  @override
  State<AdminUserManagementView> createState() =>
      _AdminUserManagementViewState();
}

class _AdminUserManagementViewState extends State<AdminUserManagementView>
    with TabReselectListener {
  final _scroll = ScrollController();

  @override
  int get shellTabIndex => AdminShellTab.users;

  @override
  TabReselectNotifier get reselectNotifier => AdminShellTab.reselected;

  @override
  void onTabReselected() => scrollToTop(_scroll);

  final Set<String> _busy = <String>{};
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  _UserFilter _filter = _UserFilter.all;

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _pickFilter() async {
    final picked = await adminPickOption<_UserFilter>(
      context,
      title: 'Filter users',
      options: _UserFilter.values,
      selected: _filter,
      labelOf: (f) => f.label,
    );
    if (picked != null) setState(() => _filter = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Users',
      leading: AdminHeaderIcon(
        tooltip: 'Search users',
        icon: Icons.search_rounded,
        onPressed: () => _searchFocus.requestFocus(),
      ),
      actions: const [AdminBell(), SizedBox(width: 4)],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: AdminSearchField(
                    controller: _search,
                    focusNode: _searchFocus,
                    hint: 'Search users...',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: _filter != _UserFilter.all,
                  smallSize: 9,
                  child: AdminSquareIconButton(
                    tooltip: 'Filter',
                    icon: Icons.filter_list_rounded,
                    onPressed: _pickFilter,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: context.read<AdminService>().watchAllUsers(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return AdminEmpty(
                    icon: Icons.error_outline_rounded,
                    message: 'Could not load users.\n${snap.error}',
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final q = _search.text.trim().toLowerCase();
                final docs = snap.data!.docs.where((doc) {
                  final d = doc.data();
                  if (!_filter.matches(d)) return false;
                  if (q.isEmpty) return true;
                  final name = (d['displayName'] as String? ?? '').toLowerCase();
                  final email = (d['email'] as String? ?? '').toLowerCase();
                  return name.contains(q) || email.contains(q);
                }).toList()
                  // Most recently updated first; users without the field last.
                  ..sort((a, b) {
                    final at = a.data()['updatedAt'];
                    final bt = b.data()['updatedAt'];
                    if (at is! Timestamp) return bt is Timestamp ? 1 : 0;
                    if (bt is! Timestamp) return -1;
                    return bt.compareTo(at);
                  });
                if (docs.isEmpty) {
                  return const AdminEmpty(
                    icon: Icons.people_outline_rounded,
                    message: 'No users found',
                  );
                }
                return ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _userTile(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final p = AdminPalette.of(context);
    final d = doc.data();
    final uid = doc.id;
    final name = (d['displayName'] as String?)?.trim() ?? '';
    final email = (d['email'] as String?)?.trim() ?? '';
    final banned = d['isBanned'] == true;
    final busy = _busy.contains(uid);
    final label = name.isNotEmpty ? name : (email.isNotEmpty ? email : uid);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: p.cardDecoration(radius: 16),
      child: Row(
        children: [
          UserAvatar(
            userId: uid,
            name: name.isNotEmpty ? name : email,
            radius: 22,
            photoUrl: (d['photoUrl'] as String?) ?? '',
            backgroundColor: p.softGreen,
            foregroundColor: p.softGreenText,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Unnamed user' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.title(p, size: 15).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.isEmpty ? 'No email' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.body(p, size: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          banned
              ? AdminPill.red(context, 'Banned')
              : AdminPill.green(context, 'Active'),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            AdminMoreButton<String>(
              tooltip: 'Manage user',
              onSelected: (v) => _onMenu(v, uid, label, banned),
              itemBuilder: (_) => [
                adminMenuItem(
                  'export',
                  Icons.folder_zip_outlined,
                  'Export evidence',
                ),
                const PopupMenuDivider(),
                banned
                    ? adminMenuItem(
                        'unban',
                        Icons.lock_open_rounded,
                        'Unban user',
                      )
                    : adminMenuItem('ban', Icons.block_flipped, 'Ban user'),
                const PopupMenuDivider(),
                adminMenuItem(
                  'delete',
                  Icons.delete_forever_rounded,
                  'Delete profile',
                  danger: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _onMenu(String v, String uid, String label, bool banned) async {
    switch (v) {
      case 'export':
        await showLegalExportDialog(context, userId: uid, userLabel: label);
      case 'ban':
        await _setBanned(uid, true);
      case 'unban':
        await _setBanned(uid, false);
      case 'delete':
        await _deleteUser(uid, label);
    }
  }

  Future<void> _setBanned(String uid, bool banned) async {
    String? reason;
    if (banned) {
      reason = await adminAskReason(
        context,
        title: 'Ban user',
        hint: 'Reason for ban (optional)',
        confirm: 'Ban',
      );
      if (reason == null || !mounted) return;
    }
    setState(() => _busy.add(uid));
    try {
      await context.read<AdminService>().setUserBanned(
            uid,
            banned: banned,
            reason: reason == null || reason.isEmpty ? null : reason,
          );
      if (mounted) adminSnack(context, banned ? 'User banned.' : 'User unbanned.');
    } catch (e) {
      if (mounted) adminSnack(context, 'Failed to update user: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  Future<void> _deleteUser(String uid, String label) async {
    final ok = await adminConfirm(
      context,
      title: 'Delete profile',
      message:
          'Delete "$label" profile and all authored posts? This cannot be undone.',
      confirm: 'Delete',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(uid));
    try {
      await context.read<AdminService>().deleteUserProfile(uid);
      if (mounted) adminSnack(context, 'User profile deleted.');
    } catch (e) {
      if (mounted) adminSnack(context, 'Failed to delete profile: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }
}
