import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/models/post_model.dart';
import '../models/claim_status.dart';
import '../services/lost_found_claim_service.dart';

/// Lost/found recovery claim entry on post detail.
class LostFoundClaimSection extends StatefulWidget {
  const LostFoundClaimSection({super.key, required this.post});

  final PostModel post;

  @override
  State<LostFoundClaimSection> createState() => _LostFoundClaimSectionState();
}

class _LostFoundClaimSectionState extends State<LostFoundClaimSection> {
  bool _starting = false;

  bool get _isLostFound =>
      widget.post.module == PostModule.lost ||
      widget.post.module == PostModule.found;

  @override
  Widget build(BuildContext context) {
    if (!_isLostFound) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();

    if (widget.post.isFulfilled) {
      return _FulfilledRecoverySection(post: widget.post);
    }

    final service = context.read<LostFoundClaimService>();
    final isAuthor = widget.post.authorId == user.uid;
    final startLabel = widget.post.module == PostModule.lost
        ? 'I found this item — start recovery'
        : 'This is my item — start claim';

    return StreamBuilder(
      stream: service.watchActiveClaimForPost(
        postId: widget.post.id,
        userId: user.uid,
      ),
      builder: (context, snap) {
        final claim = snap.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recovery confirmation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.post.module == PostModule.lost
                  ? 'When the item is returned, confirm handoff with a QR scan and GPS log.'
                  : 'When you reclaim your item, confirm return with a QR scan and GPS log.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            if (claim != null)
              AppButton(
                label: 'Open recovery claim (${claim.status.label})',
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                onPressed: () => navigatorKey.currentState?.pushNamed(
                  AppConstants.routeLostFoundClaim,
                  arguments: claim.id,
                ),
              )
            else if (!isAuthor)
              AppButton(
                label: startLabel,
                loading: _starting,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                onPressed: _starting
                    ? null
                    : () => _startClaim(
                          context,
                          user.uid,
                          user.displayName ?? user.email ?? 'User',
                        ),
              )
            else
              Text(
                'Waiting for the other party to start a recovery claim.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _startClaim(
    BuildContext context,
    String uid,
    String name,
  ) async {
    setState(() => _starting = true);
    try {
      final id = await context.read<LostFoundClaimService>().createClaim(
            post: widget.post,
            initiatorId: uid,
            initiatorName: name,
          );
      if (!context.mounted) return;
      navigatorKey.currentState?.pushNamed(
        AppConstants.routeLostFoundClaim,
        arguments: id,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}

class _FulfilledRecoverySection extends StatelessWidget {
  const _FulfilledRecoverySection({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final claimId = post.completedContractId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recovery confirmed',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This listing is no longer on the public feed or map. '
                'Both parties can find it under Profile → Completed recoveries.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer
                      .withValues(alpha: 0.85),
                ),
              ),
              if (post.fulfilledAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Confirmed: ${post.fulfilledAt!.toLocal().toString().split('.').first}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (claimId != null && claimId.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'View recovery record & GPS log',
            icon: const Icon(Icons.description_outlined, size: 20),
            onPressed: () => navigatorKey.currentState?.pushNamed(
              AppConstants.routeLostFoundClaim,
              arguments: claimId,
            ),
          ),
        ],
      ],
    );
  }
}
