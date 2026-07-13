import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/models/post_model.dart';
import '../models/contact_request_status.dart';
import '../services/contact_request_service.dart';
import 'trust_card_widget.dart';

/// Mediated contact section on post detail — hides phone until accepted.
class ContactSection extends StatefulWidget {
  const ContactSection({super.key, required this.post});

  final PostModel post;

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  bool _requesting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();

    final isAuthor = widget.post.authorId == user.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Row(
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Mutual confidence',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TrustCardWidget(
          userId: widget.post.authorId,
          displayNameFallback: widget.post.authorName,
        ),
        const SizedBox(height: 16),
        if (isAuthor) ...[
          Text(
            'Your contact',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              SelectableText(
                widget.post.contactNumber,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Others must request contact before your phone number is shown.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ] else
          StreamBuilder(
            stream: context.read<ContactRequestService>().watchActiveRequestForPost(
                  postId: widget.post.id,
                  userId: user.uid,
                ),
            builder: (context, snap) {
              final request = snap.data;

              if (request?.status.revealsContact == true) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Contact approved — use responsibly',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.post.authorName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            request!.revealedContactNumber ??
                                widget.post.contactNumber,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy number',
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            final number = request.revealedContactNumber ??
                                widget.post.contactNumber;
                            Clipboard.setData(ClipboardData(text: number));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Phone number copied')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'View contact details & meetup tips',
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      onPressed: () => navigatorKey.currentState?.pushNamed(
                        AppConstants.routeContactRequest,
                        arguments: request.id,
                      ),
                    ),
                  ],
                );
              }

              if (request?.status.isActive == true) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your contact request is awaiting approval from ${widget.post.authorName}.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'View request (${request!.status.label})',
                      icon: const Icon(Icons.hourglass_top_rounded, size: 20),
                      onPressed: () => navigatorKey.currentState?.pushNamed(
                        AppConstants.routeContactRequest,
                        arguments: request.id,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Phone numbers are hidden until ${widget.post.authorName} approves your request.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Request contact',
                    loading: _requesting,
                    icon: const Icon(Icons.mail_outline_rounded, size: 20),
                    onPressed: widget.post.isFulfilled || _requesting
                        ? null
                        : () => _requestContact(
                              context,
                              user.uid,
                              user.displayName ?? user.email ?? 'User',
                            ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _requestContact(
    BuildContext context,
    String uid,
    String name,
  ) async {
    setState(() => _requesting = true);
    try {
      final id = await context.read<ContactRequestService>().createRequest(
            post: widget.post,
            requesterId: uid,
            requesterName: name,
          );
      if (!context.mounted) return;
      navigatorKey.currentState?.pushNamed(
        AppConstants.routeContactRequest,
        arguments: id,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}
