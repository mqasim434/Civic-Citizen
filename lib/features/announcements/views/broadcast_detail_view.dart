import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_announcement.dart';
import '../../../core/services/announcement_service.dart';
import '../widgets/broadcast_poll_card.dart';
import '../../auth/controllers/auth_controller.dart';

class BroadcastDetailView extends StatefulWidget {
  const BroadcastDetailView({super.key, required this.announcement});

  final AppAnnouncement announcement;

  @override
  State<BroadcastDetailView> createState() => _BroadcastDetailViewState();
}

class _BroadcastDetailViewState extends State<BroadcastDetailView> {
  bool? _existingFeedback;
  bool _loadingFeedback = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      setState(() => _loadingFeedback = false);
      return;
    }
    final helpful = await context.read<AnnouncementService>().getFeedback(
          user.uid,
          widget.announcement.id,
        );
    if (mounted) {
      setState(() {
        _existingFeedback = helpful;
        _loadingFeedback = false;
      });
    }
  }

  Future<void> _submit(bool helpful) async {
    final user = context.read<AuthController>().user;
    if (user == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      await context.read<AnnouncementService>().submitFeedback(
            userId: user.uid,
            announcementId: widget.announcement.id,
            helpful: helpful,
          );
      if (!mounted) return;
      setState(() => _existingFeedback = helpful);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final announcement = widget.announcement;

    return Scaffold(
      appBar: AppBar(title: Text(announcement.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (announcement.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  announcement.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.outline,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              announcement.body,
              style: theme.textTheme.bodyLarge,
            ),
            if (announcement.createdAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Published ${_formatDate(announcement.createdAt!)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            if (announcement.hasPoll) ...[
              const SizedBox(height: 28),
              BroadcastPollCard(announcement: announcement),
            ],
            const SizedBox(height: 28),
            Text(
              'Was this helpful?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingFeedback)
              const Center(child: CircularProgressIndicator())
            else if (_existingFeedback != null)
              Row(
                children: [
                  Icon(
                    _existingFeedback!
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_down_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _existingFeedback!
                        ? 'You found this helpful'
                        : 'You said this was not helpful',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : () => _submit(true),
                      icon: const Icon(Icons.thumb_up_outlined),
                      label: const Text('Yes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : () => _submit(false),
                      icon: const Icon(Icons.thumb_down_outlined),
                      label: const Text('No'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
