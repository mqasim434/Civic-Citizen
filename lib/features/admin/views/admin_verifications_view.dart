import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../services/admin_service.dart';
import '../ui/admin_ui.dart';

enum _Tab { pending, approved, rejected }

/// KYC requests by status. Approve / reject inline or open the request to
/// review CNIC and selfie.
class AdminVerificationsView extends StatefulWidget {
  const AdminVerificationsView({super.key});

  @override
  State<AdminVerificationsView> createState() => _AdminVerificationsViewState();
}

class _AdminVerificationsViewState extends State<AdminVerificationsView> {
  _Tab _tab = _Tab.pending;
  bool _newestFirst = true;
  final Set<String> _busy = <String>{};

  static String _statusOf(_Tab t) {
    switch (t) {
      case _Tab.pending:
        return 'pending';
      case _Tab.approved:
        return 'verified';
      case _Tab.rejected:
        return 'rejected';
    }
  }

  static String _timeField(_Tab t) {
    switch (t) {
      case _Tab.pending:
        return 'kycSubmittedAt';
      case _Tab.approved:
        return 'verifiedAt';
      case _Tab.rejected:
        return 'rejectedAt';
    }
  }

  Future<void> _pickSort() async {
    final picked = await adminPickOption<bool>(
      context,
      title: 'Sort requests',
      options: const [true, false],
      selected: _newestFirst,
      labelOf: (v) => v ? 'Newest first' : 'Oldest first',
    );
    if (picked != null) setState(() => _newestFirst = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Verifications',
      leading: const AdminBackButton(),
      actions: [
        AdminHeaderIcon(
          tooltip: 'Sort',
          icon: Icons.filter_list_rounded,
          onPressed: _pickSort,
        ),
        const SizedBox(width: 4),
      ],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: context.read<AdminService>().watchAllUsers(),
        builder: (context, snap) {
          final all = snap.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final pendingCount = all
              .where((d) => d.data()['verificationStatus'] == 'pending')
              .length;

          final status = _statusOf(_tab);
          final field = _timeField(_tab);
          final docs = all
              .where((d) => d.data()['verificationStatus'] == status)
              .toList()
            ..sort((a, b) {
              final at = a.data()[field];
              final bt = b.data()[field];
              if (at is! Timestamp) return 1;
              if (bt is! Timestamp) return -1;
              return _newestFirst ? bt.compareTo(at) : at.compareTo(bt);
            });

          return Column(
            children: [
              AdminChipBar<_Tab>(
                options: _Tab.values,
                selected: _tab,
                expand: true,
                onSelected: (t) => setState(() => _tab = t),
                labelOf: (t) {
                  switch (t) {
                    case _Tab.pending:
                      return snap.hasData ? 'Pending ($pendingCount)' : 'Pending';
                    case _Tab.approved:
                      return 'Approved';
                    case _Tab.rejected:
                      return 'Rejected';
                  }
                },
              ),
              Expanded(
                child: snap.hasError
                    ? AdminEmpty(
                        icon: Icons.error_outline_rounded,
                        message: 'Could not load requests.\n${snap.error}',
                      )
                    : !snap.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : docs.isEmpty
                            ? AdminEmpty(
                                icon: Icons.inbox_outlined,
                                message: _tab == _Tab.pending
                                    ? 'No pending verification requests'
                                    : 'Nothing here yet',
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) =>
                                    _requestCard(docs[i], field),
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _requestCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String timeField,
  ) {
    final p = AdminPalette.of(context);
    final d = doc.data();
    final name = (d['displayName'] as String?)?.trim();
    final label = name == null || name.isEmpty
        ? (d['email'] as String? ?? 'User')
        : name;
    final t = d[timeField];
    final when = t is Timestamp ? adminTimeAgo(t.toDate()) : '';
    final verb = switch (_tab) {
      _Tab.pending => 'Requested',
      _Tab.approved => 'Approved',
      _Tab.rejected => 'Rejected',
    };
    final photo = (d['photoUrl'] as String?)?.isNotEmpty == true
        ? d['photoUrl'] as String
        : (d['selfieImageUrl'] as String? ?? '');
    final busy = _busy.contains(doc.id);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: p.cardDecoration(radius: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => navigatorKey.currentState?.pushNamed(
            AppConstants.routeAdminUserVerification,
            arguments: doc.id,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                UserAvatar(
                  userId: doc.id,
                  name: label,
                  radius: 26,
                  photoUrl: photo,
                  backgroundColor: p.softGreen,
                  foregroundColor: p.softGreenText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AdminText.title(p, size: 15).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        when.isEmpty ? verb : '$verb $when',
                        style: AdminText.body(p, size: 12),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_tab == _Tab.pending) ...[
                  _MiniButton(
                    label: 'Approve',
                    onTap: () => _approve(doc.id, label),
                  ),
                  const SizedBox(width: 6),
                  _MiniButton(
                    label: 'Reject',
                    danger: true,
                    onTap: () => _reject(doc.id),
                  ),
                ] else if (_tab == _Tab.approved)
                  AdminPill.green(context, 'Verified')
                else
                  AdminPill.red(context, 'Rejected'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approve(String uid, String label) async {
    final ok = await adminConfirm(
      context,
      title: 'Approve $label?',
      message: 'Make sure you have checked their CNIC and selfie. '
          'Tap the request to review them first.',
      confirm: 'Approve',
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(uid));
    try {
      await context.read<AdminService>().markVerified(uid);
      if (mounted) adminSnack(context, '$label verified.');
    } catch (e) {
      if (mounted) adminSnack(context, 'Failed to approve: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  Future<void> _reject(String uid) async {
    final reason = await adminAskReason(
      context,
      title: 'Reject verification',
      hint: 'Reason (shown to the user)',
      confirm: 'Reject',
    );
    if (reason == null || !mounted) return;
    setState(() => _busy.add(uid));
    try {
      await context.read<AdminService>().markRejected(
            uid,
            reason: reason.isEmpty ? null : reason,
          );
      if (mounted) adminSnack(context, 'Verification rejected.');
    } catch (e) {
      if (mounted) adminSnack(context, 'Failed to reject: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 30,
        decoration: BoxDecoration(
          gradient: danger ? null : p.buttonGradient,
          color: danger ? p.softRed : null,
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                label,
                style: AdminText.label(
                  danger ? p.softRedText : Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
