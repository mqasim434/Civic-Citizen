import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/claim_status.dart';
import '../models/lost_found_claim.dart';
import '../services/lost_found_claim_service.dart';

class ClaimQrView extends StatelessWidget {
  const ClaimQrView({super.key, required this.claimId});

  final String claimId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.read<LostFoundClaimService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery QR code')),
      body: StreamBuilder<LostFoundClaim?>(
        stream: service.watchClaim(claimId),
        builder: (context, snap) {
          final claim = snap.data;
          if (claim == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (claim.status != ClaimStatus.readyForHandshake) {
            return const Center(
              child: Text('QR is not available for this claim'),
            );
          }
          if (!claim.qrValid) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_off_outlined,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    const Text(
                      'QR code expired',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Go back and tap Refresh QR before the other party scans.',
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
                  'Ask the other party to scan this code when you meet in person.',
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
                    data: claim.qrPayload,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  claim.itemTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (claim.qrExpiresAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Valid until ${claim.qrExpiresAt!.toLocal().toString().split('.').first}',
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
