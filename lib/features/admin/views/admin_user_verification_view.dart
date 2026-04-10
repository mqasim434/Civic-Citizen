import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../services/admin_service.dart';

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
          title: const Text('Decline verification'),
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
              child: const Text('Decline'),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review verification'),
      ),
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
                Text('Status: $status', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(name, style: theme.textTheme.headlineSmall),
                Text(email, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                Text('CNIC — front', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _img(front),
                const SizedBox(height: 16),
                Text('CNIC — back', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _img(back),
                const SizedBox(height: 16),
                Text('Selfie', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _img(selfie),
                const SizedBox(height: 32),
                if (status == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _verify,
                          child: _busy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Mark verified'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _decline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                ],
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
        color: Colors.black12,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
