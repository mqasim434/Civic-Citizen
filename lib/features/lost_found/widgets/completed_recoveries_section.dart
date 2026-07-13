import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../posts/models/post_listing_status.dart';
import '../../posts/models/post_model.dart';
import '../../posts/services/post_service.dart';
import '../models/lost_found_claim.dart';
import '../services/lost_found_claim_service.dart';

/// Profile section: completed lost/found recoveries.
class CompletedRecoveriesSection extends StatelessWidget {
  const CompletedRecoveriesSection({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<LostFoundClaim>>(
      stream: context
          .read<LostFoundClaimService>()
          .watchCompletedClaimsForUser(userId),
      builder: (context, snap) {
        final claims = snap.data ?? [];
        if (claims.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Completed recoveries',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lost/found items removed from the public feed after QR confirmation.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            ...claims.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompletedRecoveryCard(claim: c, userId: userId),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompletedRecoveryCard extends StatelessWidget {
  const _CompletedRecoveryCard({
    required this.claim,
    required this.userId,
  });

  final LostFoundClaim claim;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherParty =
        userId == claim.ownerId ? claim.finderName : claim.ownerName;
    final roleLabel =
        userId == claim.ownerId ? 'Returned via' : 'Confirmed with';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Recovery complete',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    claim.postModule.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              claim.itemTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$roleLabel $otherParty',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (claim.handshakeAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Confirmed: ${claim.handshakeAt!.toLocal().toString().split('.').first}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => navigatorKey.currentState?.pushNamed(
                    AppConstants.routeLostFoundClaim,
                    arguments: claim.id,
                  ),
                  child: const Text('View record'),
                ),
                OutlinedButton(
                  onPressed: () => _openPost(context),
                  child: const Text('View listing'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPost(BuildContext context) async {
    final fetched = await context.read<PostService>().getPost(claim.postId);
    if (!context.mounted) return;
    final post = fetched ??
        PostModel(
          id: claim.postId,
          module: claim.postModule,
          title: claim.itemTitle,
          description: claim.itemDescription,
          authorId: claim.postModule == PostModule.lost
              ? claim.ownerId
              : claim.finderId,
          authorName: claim.postModule == PostModule.lost
              ? claim.ownerName
              : claim.finderName,
          contactNumber: '',
          category: claim.itemCategory,
          location: claim.itemLocation,
          listingStatus: PostListingStatus.fulfilled,
          completedContractId: claim.id,
          fulfilledAt: claim.completedAt ?? claim.handshakeAt,
        );
    navigatorKey.currentState?.pushNamed(
      AppConstants.routePostDetail,
      arguments: post,
    );
  }
}
