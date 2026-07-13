import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/models/post_model.dart';
import '../models/claim_status.dart';
import '../models/lost_found_claim.dart';
import '../services/lost_found_claim_service.dart';

class ClaimDetailView extends StatefulWidget {
  const ClaimDetailView({super.key, required this.claimId});

  final String claimId;

  @override
  State<ClaimDetailView> createState() => _ClaimDetailViewState();
}

class _ClaimDetailViewState extends State<ClaimDetailView> {
  bool _confirming = false;
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;
    final service = context.read<LostFoundClaimService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery claim')),
      body: StreamBuilder<LostFoundClaim?>(
        stream: service.watchClaim(widget.claimId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final claim = snap.data;
          if (claim == null || user == null) {
            return const Center(child: Text('Recovery claim not found'));
          }
          if (!claim.involvesUser(user.uid)) {
            return const Center(
              child: Text('You are not a party to this recovery claim'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBanner(status: claim.status),
                const SizedBox(height: 20),
                Text(
                  claim.itemTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (claim.itemCategory != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    claim.itemCategory!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _InfoRow(label: 'Post type', value: claim.postModule.label),
                _InfoRow(label: 'Your role', value: claim.roleLabelFor(user.uid)),
                _InfoRow(label: 'Owner', value: claim.ownerName),
                _InfoRow(label: 'Finder', value: claim.finderName),
                if (claim.itemLocation != null &&
                    claim.itemLocation!.trim().isNotEmpty)
                  _InfoRow(label: 'Location', value: claim.itemLocation!),
                const SizedBox(height: 20),
                Text(
                  'Recovery summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    claim.summaryText ?? claim.itemDescription,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
                if (claim.status == ClaimStatus.completed) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Handoff log',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (claim.handshakeAt != null)
                    _InfoRow(
                      label: 'Confirmed at',
                      value: claim.handshakeAt!.toLocal().toString().split('.').first,
                    ),
                  if (claim.handshakeLatitude != null &&
                      claim.handshakeLongitude != null)
                    _InfoRow(
                      label: 'GPS',
                      value:
                          '${claim.handshakeLatitude!.toStringAsFixed(5)}, ${claim.handshakeLongitude!.toStringAsFixed(5)}',
                    ),
                  if (claim.handshakeAddress != null &&
                      claim.handshakeAddress!.trim().isNotEmpty)
                    _InfoRow(label: 'Address', value: claim.handshakeAddress!),
                ],
                const SizedBox(height: 28),
                ..._buildActions(context, claim, user.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    LostFoundClaim claim,
    String uid,
  ) {
    final service = context.read<LostFoundClaimService>();

    switch (claim.status) {
      case ClaimStatus.pendingConfirm:
        if (claim.isQrDisplayUser(uid)) {
          return [
            AppButton(
              label: 'Confirm — ready to meet',
              loading: _confirming,
              icon: const Icon(Icons.check_rounded, size: 20),
              onPressed: _confirming
                  ? null
                  : () async {
                      setState(() => _confirming = true);
                      try {
                        await service.confirmClaim(
                          claimId: claim.id,
                          userId: uid,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR code is ready — show it at meetup'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _confirming = false);
                      }
                    },
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm when you are ready to meet the other party in person.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          ];
        }
        return [
          Text(
            'Waiting for the post author to confirm they are ready to meet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
          ),
        ];
      case ClaimStatus.readyForHandshake:
        final actions = <Widget>[];
        if (claim.isQrDisplayUser(uid)) {
          actions.addAll([
            AppButton(
              label: 'Show QR code',
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              onPressed: () => navigatorKey.currentState?.pushNamed(
                AppConstants.routeClaimQr,
                arguments: claim.id,
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Refresh QR',
              outlined: true,
              loading: _refreshing,
              onPressed: _refreshing
                  ? null
                  : () async {
                      setState(() => _refreshing = true);
                      try {
                        await service.refreshQrToken(
                          claimId: claim.id,
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
                      } finally {
                        if (mounted) setState(() => _refreshing = false);
                      }
                    },
            ),
          ]);
        }
        if (claim.isQrScanner(uid)) {
          if (actions.isNotEmpty) actions.add(const SizedBox(height: 12));
          actions.add(
            AppButton(
              label: 'Scan QR to confirm',
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              onPressed: () => navigatorKey.currentState?.pushNamed(
                AppConstants.routeClaimScan,
                arguments: claim.id,
              ),
            ),
          );
        }
        return actions;
      case ClaimStatus.completed:
        return [
          Text(
            'Recovery confirmed. This post is removed from the public feed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ];
      case ClaimStatus.cancelled:
        return [
          Text(
            'This recovery claim was cancelled.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ];
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case ClaimStatus.pendingConfirm:
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
        icon = Icons.hourglass_top_rounded;
      case ClaimStatus.readyForHandshake:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        icon = Icons.qr_code_rounded;
      case ClaimStatus.completed:
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        icon = Icons.check_circle_outline_rounded;
      case ClaimStatus.cancelled:
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        icon = Icons.cancel_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
