import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/contract_status.dart';
import '../models/lend_borrow_contract.dart';
import '../services/lend_borrow_contract_service.dart';

/// Lender displays QR code for borrower to scan at meetup.
class ContractQrView extends StatelessWidget {
  const ContractQrView({super.key, required this.contractId});

  final String contractId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.read<LendBorrowContractService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Handoff QR code')),
      body: StreamBuilder<LendBorrowContract?>(
        stream: service.watchContract(contractId),
        builder: (context, snap) {
          final contract = snap.data;
          if (contract == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (contract.status != ContractStatus.readyForHandshake) {
            return const Center(child: Text('QR is not available for this agreement'));
          }
          if (!contract.qrValid) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_off_outlined, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    const Text(
                      'QR code expired',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Go back and tap Refresh QR before the borrower scans.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Ask the borrower to scan this code when you meet in person.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: contract.qrPayload,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  contract.itemTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (contract.qrExpiresAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Valid until ${contract.qrExpiresAt!.toLocal().toString().split('.').first}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
