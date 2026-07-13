import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/models/post_model.dart';
import '../../posts/services/post_service.dart';
import '../models/contact_request.dart';
import '../models/contact_request_status.dart';
import '../models/meetup_suggestion.dart';
import '../services/contact_request_service.dart';
import '../services/meetup_suggestion_service.dart';
import '../widgets/meetup_suggestions_widget.dart';
import '../widgets/trust_card_widget.dart';

class ContactRequestDetailView extends StatefulWidget {
  const ContactRequestDetailView({super.key, required this.requestId});

  final String requestId;

  @override
  State<ContactRequestDetailView> createState() =>
      _ContactRequestDetailViewState();
}

class _ContactRequestDetailViewState extends State<ContactRequestDetailView> {
  bool _acting = false;
  bool _savingMeetup = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    final service = context.read<ContactRequestService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Contact request')),
      body: StreamBuilder<ContactRequest?>(
        stream: service.watchRequest(widget.requestId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final request = snap.data;
          if (request == null || user == null) {
            return const Center(child: Text('Contact request not found'));
          }
          if (!request.involvesUser(user.uid)) {
            return const Center(
              child: Text('You are not a party to this contact request'),
            );
          }

          final isAuthor = request.authorId == user.uid;
          final otherId = request.otherPartyId(user.uid);
          final otherName = request.otherPartyName(user.uid);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(status: request.status),
                const SizedBox(height: 20),
                Text(
                  request.itemTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.postModule.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Your role',
                  value: isAuthor ? 'Post author' : 'Requester',
                ),
                _InfoRow(label: 'Other party', value: otherName),
                const SizedBox(height: 16),
                TrustCardWidget(
                  userId: otherId,
                  displayNameFallback: otherName,
                  compact: true,
                ),
                if (request.status.revealsContact) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Shared contact',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          request.revealedContactNumber ?? '—',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      if (request.revealedContactNumber != null)
                        IconButton(
                          tooltip: 'Copy',
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: request.revealedContactNumber!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Phone number copied')),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MeetupSection(
                    request: request,
                    savingMeetup: _savingMeetup,
                    onSelect: (suggestion) => _saveMeetup(
                      context,
                      request.id,
                      user.uid,
                      suggestion.label,
                      suggestion.latitude,
                      suggestion.longitude,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (request.status == ContactRequestStatus.pending) ...[
                  if (isAuthor) ...[
                    AppButton(
                      label: 'Accept & share contact',
                      loading: _acting,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      onPressed: _acting
                          ? null
                          : () => _accept(context, user.uid),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Decline request',
                      loading: _acting,
                      outlined: true,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _acting
                          ? null
                          : () => _decline(context, user.uid),
                    ),
                  ] else
                    AppButton(
                      label: 'Cancel request',
                      loading: _acting,
                      outlined: true,
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      onPressed: _acting
                          ? null
                          : () => _cancel(context, user.uid),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _accept(BuildContext context, String uid) async {
    setState(() => _acting = true);
    try {
      await context.read<ContactRequestService>().acceptRequest(
            requestId: widget.requestId,
            authorId: uid,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _decline(BuildContext context, String uid) async {
    setState(() => _acting = true);
    try {
      await context.read<ContactRequestService>().declineRequest(
            requestId: widget.requestId,
            authorId: uid,
          );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _cancel(BuildContext context, String uid) async {
    setState(() => _acting = true);
    try {
      await context.read<ContactRequestService>().cancelRequest(
            requestId: widget.requestId,
            requesterId: uid,
          );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _saveMeetup(
    BuildContext context,
    String requestId,
    String userId,
    String label,
    double? latitude,
    double? longitude,
  ) async {
    setState(() => _savingMeetup = true);
    try {
      await context.read<ContactRequestService>().saveMeetupSuggestion(
            requestId: requestId,
            userId: userId,
            label: label,
            latitude: latitude,
            longitude: longitude,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Meetup spot saved: $label')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingMeetup = false);
    }
  }
}

class _MeetupSection extends StatelessWidget {
  const _MeetupSection({
    required this.request,
    required this.savingMeetup,
    required this.onSelect,
  });

  final ContactRequest request;
  final bool savingMeetup;
  final void Function(MeetupSuggestion suggestion) onSelect;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(PostModel?, List<MeetupSuggestion>)>(
      future: _load(context),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const MeetupSuggestionsWidget(
            suggestions: [],
            loading: true,
          );
        }
        final suggestions = snap.data?.$2 ??
            MeetupSuggestionService.suggestionsFromCoordinates(
              locationLabel: request.itemTitle,
            );
        return MeetupSuggestionsWidget(
          suggestions: suggestions,
          selectedLabel: request.suggestedMeetupLabel,
          onSelect: savingMeetup ? null : onSelect,
        );
      },
    );
  }

  Future<(PostModel?, List<MeetupSuggestion>)> _load(
    BuildContext context,
  ) async {
    final post =
        await context.read<PostService>().getPost(request.postId);
    if (post != null) {
      final suggestions =
          await MeetupSuggestionService.suggestionsForPost(post);
      return (post, suggestions);
    }
    return (
      null,
      MeetupSuggestionService.suggestionsFromCoordinates(
        locationLabel: request.itemTitle,
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final ContactRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = switch (status) {
      ContactRequestStatus.accepted => (
          theme.colorScheme.tertiaryContainer,
          Icons.check_circle_outline,
        ),
      ContactRequestStatus.declined ||
      ContactRequestStatus.cancelled =>
        (
          theme.colorScheme.errorContainer.withValues(alpha: 0.6),
          Icons.info_outline,
        ),
      ContactRequestStatus.pending => (
          theme.colorScheme.primaryContainer,
          Icons.hourglass_top_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
