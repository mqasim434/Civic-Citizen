import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/contract_status.dart';
import '../models/lend_borrow_contract.dart';
import '../services/lend_borrow_contract_service.dart';

/// Hub for reviewing terms, signing, and QR handshake steps.
class ContractDetailView extends StatelessWidget {
  const ContractDetailView({super.key, required this.contractId});

  final String contractId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    final service = context.read<LendBorrowContractService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lend / borrow agreement')),
      body: StreamBuilder<LendBorrowContract?>(
        stream: service.watchContract(contractId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contract = snap.data;
          if (contract == null || user == null) {
            return const Center(child: Text('Agreement not found'));
          }
          if (!contract.involvesUser(user.uid)) {
            return const Center(child: Text('You are not a party to this agreement'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(status: contract.status),
                const SizedBox(height: 20),
                Text(
                  contract.itemTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (contract.itemCategory != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    contract.itemCategory!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _InfoRow(label: 'Lender', value: contract.lenderName),
                _InfoRow(label: 'Borrower', value: contract.borrowerName),
                if (contract.itemCondition != null &&
                    contract.itemCondition!.trim().isNotEmpty)
                  _InfoRow(label: 'Condition', value: contract.itemCondition!),
                const SizedBox(height: 20),
                Text(
                  'Agreement terms',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contract.termsText,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Signatures',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SignatureTile(
                        label: 'Lender',
                        signed: contract.lenderSignatureUrl != null,
                        imageUrl: contract.lenderSignatureUrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SignatureTile(
                        label: 'Borrower',
                        signed: contract.borrowerSignatureUrl != null,
                        imageUrl: contract.borrowerSignatureUrl,
                      ),
                    ),
                  ],
                ),
                if (contract.status == ContractStatus.completed) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Exchange log',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _HandshakeLogCard(contract: contract),
                ],
                const SizedBox(height: 28),
                ..._actions(context, contract, user.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    LendBorrowContract contract,
    String uid,
  ) {
    final actions = <Widget>[];

    if (contract.status == ContractStatus.pendingLenderSignature &&
        contract.isLender(uid)) {
      actions.add(
        AppButton(
          label: 'Sign as lender',
          icon: const Icon(Icons.draw_rounded, size: 20),
          onPressed: () => _openSign(context, contract.id, isLender: true),
        ),
      );
    }

    if (contract.status == ContractStatus.pendingBorrowerSignature &&
        contract.isBorrower(uid)) {
      actions.add(
        AppButton(
          label: 'Sign as borrower',
          icon: const Icon(Icons.draw_rounded, size: 20),
          onPressed: () => _openSign(context, contract.id, isLender: false),
        ),
      );
    }

    if (contract.status == ContractStatus.readyForHandshake) {
      if (contract.isLender(uid)) {
        actions.addAll([
          AppButton(
            label: 'Show QR code',
            icon: const Icon(Icons.qr_code_rounded, size: 20),
            onPressed: () => navigatorKey.currentState?.pushNamed(
              AppConstants.routeContractQr,
              arguments: contract.id,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Refresh QR',
            outlined: true,
            onPressed: () => _refreshQr(context, contract.id),
          ),
        ]);
      }
      if (contract.isBorrower(uid)) {
        actions.add(
          AppButton(
            label: 'Scan QR to confirm exchange',
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            onPressed: () => navigatorKey.currentState?.pushNamed(
              AppConstants.routeContractScan,
              arguments: contract.id,
            ),
          ),
        );
      }
    }

    if (actions.isEmpty &&
        contract.status != ContractStatus.completed &&
        contract.status != ContractStatus.cancelled) {
      actions.add(
        Text(
          contract.isLender(uid)
              ? 'Waiting for the borrower to sign.'
              : 'Waiting for the lender to sign.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      );
    }

    return actions;
  }

  void _openSign(BuildContext context, String contractId, {required bool isLender}) {
    navigatorKey.currentState?.pushNamed(
      AppConstants.routeContractSignature,
      arguments: {'contractId': contractId, 'isLender': isLender},
    );
  }

  Future<void> _refreshQr(BuildContext context, String contractId) async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;
    try {
      await context.read<LendBorrowContractService>().refreshQrToken(
            contractId: contractId,
            userId: uid,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code refreshed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final ContractStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case ContractStatus.completed:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        icon = Icons.check_circle_outline_rounded;
      case ContractStatus.readyForHandshake:
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        icon = Icons.qr_code_2_rounded;
      case ContractStatus.cancelled:
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        icon = Icons.cancel_outlined;
      default:
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
        icon = Icons.pending_actions_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: fg,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureTile extends StatelessWidget {
  const _SignatureTile({
    required this.label,
    required this.signed,
    this.imageUrl,
  });

  final String label;
  final bool signed;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
              color: theme.colorScheme.surface,
            ),
            child: signed && imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl!, fit: BoxFit.contain),
                  )
                : Center(
                    child: Text(
                      'Pending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _HandshakeLogCard extends StatelessWidget {
  const _HandshakeLogCard({required this.contract});

  final LendBorrowContract contract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contract.handshakeAt != null)
            _InfoRow(
              label: 'Time',
              value: contract.handshakeAt!.toLocal().toString().split('.').first,
            ),
          if (contract.handshakeLatitude != null &&
              contract.handshakeLongitude != null)
            _InfoRow(
              label: 'GPS',
              value:
                  '${contract.handshakeLatitude!.toStringAsFixed(6)}, ${contract.handshakeLongitude!.toStringAsFixed(6)}',
            ),
          if (contract.handshakeAddress != null &&
              contract.handshakeAddress!.trim().isNotEmpty)
            _InfoRow(label: 'Address', value: contract.handshakeAddress!),
        ],
      ),
    );
  }
}
