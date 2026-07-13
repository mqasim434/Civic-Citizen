import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_announcement.dart';
import '../../../core/services/announcement_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Interactive poll on a broadcast (single vote per user).
class BroadcastPollCard extends StatefulWidget {
  const BroadcastPollCard({
    super.key,
    required this.announcement,
    this.compact = false,
  });

  final AppAnnouncement announcement;
  final bool compact;

  @override
  State<BroadcastPollCard> createState() => _BroadcastPollCardState();
}

class _BroadcastPollCardState extends State<BroadcastPollCard> {
  String? _selectedOptionId;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadVote();
  }

  Future<void> _loadVote() async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final vote = await context.read<AnnouncementService>().getPollVote(
          user.uid,
          widget.announcement.id,
        );
    if (mounted) {
      setState(() {
        _selectedOptionId = vote;
        _loading = false;
      });
    }
  }

  Future<void> _vote(String optionId) async {
    final user = context.read<AuthController>().user;
    if (user == null || _submitting || _selectedOptionId != null) return;

    setState(() => _submitting = true);
    try {
      await context.read<AnnouncementService>().submitPollVote(
            userId: user.uid,
            announcementId: widget.announcement.id,
            optionId: optionId,
          );
      if (!mounted) return;
      setState(() => _selectedOptionId = optionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote recorded')),
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
    if (!widget.announcement.hasPoll) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final announcement = widget.announcement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          announcement.pollQuestion!,
          style: (widget.compact
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.titleMedium)
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_selectedOptionId != null)
          ...announcement.pollOptions.map(
            (option) {
              final selected = option.id == _selectedOptionId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(color: theme.colorScheme.primary)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(option.text)),
                    ],
                  ),
                ),
              );
            },
          )
        else
          ...announcement.pollOptions.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: _submitting ? null : () => _vote(option.id),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: Text(option.text),
              ),
            ),
          ),
      ],
    );
  }
}
