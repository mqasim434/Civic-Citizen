import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../services/admin_service.dart';
import '../ui/admin_ui.dart';
import '../widgets/legal_export_dialog.dart';

class AdminUserVerificationView extends StatefulWidget {
  const AdminUserVerificationView({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserVerificationView> createState() => _AdminUserVerificationViewState();
}

class _AdminUserVerificationViewState extends State<AdminUserVerificationView> {
  bool _busy = false;

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await context.read<AdminService>().markVerified(widget.userId);
      if (mounted) navigatorKey.currentState?.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Reject verification'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Shown to the user',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await context.read<AdminService>().markRejected(
            widget.userId,
            reason: result.isEmpty ? null : result,
          );
      if (mounted) navigatorKey.currentState?.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    return AdminPage(
      title: 'Review verification',
      leading: const AdminBackButton(),
      actions: [
        AdminHeaderIcon(
          tooltip: 'Export evidence package',
          icon: Icons.folder_zip_outlined,
          onPressed: () => showLegalExportDialog(
            context,
            userId: widget.userId,
            userLabel: widget.userId,
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('User not found'));
          }
          final d = snap.data!.data()!;
          final name = d['displayName'] as String? ?? '';
          final email = d['email'] as String? ?? '';
          final status = d['verificationStatus'] as String? ?? '';
          final front = d['cnicFrontImageUrl'] as String?;
          final back = d['cnicBackImageUrl'] as String?;
          final selfie = d['selfieImageUrl'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AdminText.title(p, size: 20)),
                          const SizedBox(height: 2),
                          Text(email, style: AdminText.body(p, size: 14)),
                        ],
                      ),
                    ),
                    switch (status) {
                      'verified' => AdminPill.green(context, 'Verified'),
                      'rejected' => AdminPill.red(context, 'Rejected'),
                      'pending' => AdminPill.amber(context, 'Pending'),
                      _ => AdminPill.grey(context, status.isEmpty ? 'None' : status),
                    },
                  ],
                ),
                const SizedBox(height: 24),
                Text('CNIC front', style: AdminText.title(p, size: 14)),
                const SizedBox(height: 8),
                _img(front),
                const SizedBox(height: 16),
                Text('CNIC back', style: AdminText.title(p, size: 14)),
                const SizedBox(height: 8),
                _img(back),
                const SizedBox(height: 16),
                Text('Selfie', style: AdminText.title(p, size: 14)),
                const SizedBox(height: 8),
                _img(selfie),
                const SizedBox(height: 32),
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: AdminButton(
                          label: 'Approve',
                          icon: Icons.check_rounded,
                          busy: _busy,
                          onPressed: _verify,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminButton(
                          label: 'Reject',
                          danger: true,
                          onPressed: _busy ? null : _decline,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _img(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 180,
        decoration: AdminPalette.of(context).cardDecoration(radius: 14),
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.error_outline),
      ),
    );
  }
}
