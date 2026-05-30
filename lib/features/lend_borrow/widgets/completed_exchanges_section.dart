import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../posts/models/post_listing_status.dart';
import '../../posts/models/post_model.dart';
import '../../posts/services/post_service.dart';
import '../models/lend_borrow_contract.dart';
import '../services/lend_borrow_contract_service.dart';

/// Profile section: completed lend/borrow exchanges for lender or borrower.
class CompletedExchangesSection extends StatelessWidget {
  const CompletedExchangesSection({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<LendBorrowContract>>(
      stream: context
          .read<LendBorrowContractService>()
          .watchCompletedContractsForUser(userId),
      builder: (context, snap) {
        final contracts = snap.data ?? [];
        if (contracts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Completed exchanges',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lend/borrow items removed from the public feed after handshake.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            ...contracts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompletedExchangeCard(contract: c, userId: userId),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompletedExchangeCard extends StatelessWidget {
  const _CompletedExchangeCard({
    required this.contract,
    required this.userId,
  });

  final LendBorrowContract contract;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLender = contract.isLender(userId);
    final otherParty =
        isLender ? contract.borrowerName : contract.lenderName;
    final roleLabel = isLender ? 'You lent to' : 'You borrowed from';

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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Exchange complete',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    contract.postModule.label,
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
              contract.itemTitle,
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
            if (contract.handshakeAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Handoff: ${contract.handshakeAt!.toLocal().toString().split('.').first}',
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
                    AppConstants.routeLendBorrowContract,
                    arguments: contract.id,
                  ),
                  child: const Text('View agreement'),
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
    final fetched = await context.read<PostService>().getPost(contract.postId);
    if (!context.mounted) return;
    final post = fetched ??
        PostModel(
          id: contract.postId,
          module: contract.postModule,
          title: contract.itemTitle,
          description: contract.itemDescription,
          authorId: contract.postModule == PostModule.lend
              ? contract.lenderId
              : contract.borrowerId,
          authorName: contract.postModule == PostModule.lend
              ? contract.lenderName
              : contract.borrowerName,
          contactNumber: '',
          category: contract.itemCategory,
          itemCondition: contract.itemCondition,
          location: contract.itemLocation,
          listingStatus: PostListingStatus.fulfilled,
          completedContractId: contract.id,
          fulfilledAt: contract.completedAt ?? contract.handshakeAt,
        );
    navigatorKey.currentState?.pushNamed(
      AppConstants.routePostDetail,
      arguments: post,
    );
  }
}
