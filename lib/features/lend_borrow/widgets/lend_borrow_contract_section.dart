import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/models/post_model.dart';
import '../models/contract_status.dart';
import '../services/lend_borrow_contract_service.dart';

/// Lend/borrow digital agreement entry on post detail.
class LendBorrowContractSection extends StatefulWidget {
  const LendBorrowContractSection({super.key, required this.post});

  final PostModel post;

  @override
  State<LendBorrowContractSection> createState() =>
      _LendBorrowContractSectionState();
}

class _LendBorrowContractSectionState extends State<LendBorrowContractSection> {
  bool _starting = false;

  bool get _isLendBorrow =>
      widget.post.module == PostModule.lend ||
      widget.post.module == PostModule.borrow;

  @override
  Widget build(BuildContext context) {
    if (!_isLendBorrow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();

    if (widget.post.isFulfilled) {
      return _FulfilledSection(post: widget.post);
    }

    final service = context.read<LendBorrowContractService>();
    final isAuthor = widget.post.authorId == user.uid;

    return StreamBuilder(
      stream: service.watchActiveContractForPost(
        postId: widget.post.id,
        userId: user.uid,
      ),
      builder: (context, snap) {
        final contract = snap.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 32),
            Row(
              children: [
                Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Digital agreement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sign on-screen, then confirm the physical exchange with a QR handshake and GPS log.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (widget.post.itemCondition != null &&
                widget.post.itemCondition!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Condition: ${widget.post.itemCondition}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            if (contract != null)
              AppButton(
                label: 'Open agreement (${contract.status.label})',
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                onPressed: () => navigatorKey.currentState?.pushNamed(
                  AppConstants.routeLendBorrowContract,
                  arguments: contract.id,
                ),
              )
            else if (!isAuthor)
              AppButton(
                label: 'Start digital agreement',
                loading: _starting,
                icon: const Icon(Icons.handshake_outlined, size: 20),
                onPressed: _starting
                    ? null
                    : () => _startAgreement(
                          context,
                          user.uid,
                          user.displayName ?? user.email ?? 'User',
                        ),
              )
            else
              Text(
                'Waiting for the other party to start the agreement.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _startAgreement(
    BuildContext context,
    String uid,
    String name,
  ) async {
    setState(() => _starting = true);
    try {
      final id = await context.read<LendBorrowContractService>().createContract(
            post: widget.post,
            initiatorId: uid,
            initiatorName: name,
          );
      if (!context.mounted) return;
      navigatorKey.currentState?.pushNamed(
        AppConstants.routeLendBorrowContract,
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

class _FulfilledSection extends StatelessWidget {
  const _FulfilledSection({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contractId = post.completedContractId;

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
                      'Exchange completed',
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
                'Both parties can find it under Profile → Completed exchanges.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.85),
                ),
              ),
              if (post.fulfilledAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Completed: ${post.fulfilledAt!.toLocal().toString().split('.').first}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (contractId != null && contractId.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'View agreement & GPS log',
            icon: const Icon(Icons.description_outlined, size: 20),
            onPressed: () => navigatorKey.currentState?.pushNamed(
              AppConstants.routeLendBorrowContract,
              arguments: contractId,
            ),
          ),
        ],
      ],
    );
  }
}
