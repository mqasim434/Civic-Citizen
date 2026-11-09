import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/ad_model.dart';
import '../services/ad_service.dart';
import '../../admin/ui/admin_ui.dart';

class AdminAdsModerationView extends StatefulWidget {
  const AdminAdsModerationView({super.key});

  @override
  State<AdminAdsModerationView> createState() => _AdminAdsModerationViewState();
}

class _AdminAdsModerationViewState extends State<AdminAdsModerationView> {
  final _rateController = TextEditingController();
  bool _savingRate = false;
  bool _rateSeeded = false;

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveRate() async {
    final parsed = int.tryParse(_rateController.text.trim());
    if (parsed == null || parsed < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid rate (1 or more).')),
      );
      return;
    }
    setState(() => _savingRate = true);
    try {
      await context.read<AdService>().setAdPointsCost(parsed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad rate set to $parsed points')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _savingRate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ads = context.read<AdService>();

    return StreamBuilder<List<AdModel>>(
      stream: ads.watchAllAdsForAdmin(),
      builder: (context, snap) {
        final list = snap.data ?? [];
        final loading = snap.connectionState == ConnectionState.waiting &&
            snap.data == null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            StreamBuilder<int>(
              stream: ads.watchAdPointsCost(),
              builder: (context, costSnap) {
                final cost =
                    costSnap.data ?? AppConstants.defaultAdPointsCost;
                if (!_rateSeeded &&
                    costSnap.connectionState != ConnectionState.waiting) {
                  _rateSeeded = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _rateController.text = '$cost';
                  });
                }
                return Container(
                  decoration: AdminPalette.of(context).cardDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Minimum ad rate',
                          style: AdminText.title(AdminPalette.of(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Points users must spend to run an ad '
                          '(default ${AppConstants.defaultAdPointsCost}). '
                          'Current: $cost pts.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rateController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Points cost',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: _savingRate ? null : _saveRate,
                              child: _savingRate
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const AdminSectionHeader(title: 'All ads'),
            const SizedBox(height: 8),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No ads yet',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else
              ...list.map((ad) => _AdTile(ad: ad, ads: ads)),
          ],
        );
      },
    );
  }
}


/// Ads page inside the admin panel (opened from More).
class AdminAdsView extends StatelessWidget {
  const AdminAdsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPage(
      title: 'Ads',
      leading: AdminBackButton(),
      body: AdminAdsModerationView(),
    );
  }
}

class _AdTile extends StatelessWidget {
  const _AdTile({required this.ad, required this.ads});

  final AdModel ad;
  final AdService ads;

  @override
  Widget build(BuildContext context) {
    final p = AdminPalette.of(context);
    final pill = switch (ad.status) {
      AdStatus.active => ad.isLive
          ? AdminPill.green(context, 'Active')
          : AdminPill.grey(context, 'Expired'),
      AdStatus.paused => AdminPill.amber(context, 'Paused'),
      AdStatus.expired => AdminPill.grey(context, 'Expired'),
      AdStatus.stopped => AdminPill.grey(context, 'Stopped'),
      AdStatus.removed => AdminPill.red(context, 'Removed'),
    };
    final canRemove =
        ad.status != AdStatus.removed && ad.status != AdStatus.stopped;
    final meta = [
      ad.authorName,
      if (ad.city != null && ad.city!.isNotEmpty) ad.city!,
      '${ad.pointsSpent} pts',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: p.cardDecoration(radius: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
                  ? Image.network(
                      ad.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _icon(p),
                    )
                  : _icon(p),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.title(p, size: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.body(p, size: 12),
                ),
                if (ad.endsAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Ends ${adminDate(ad.endsAt!)}',
                    style: AdminText.body(p, size: 11.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          pill,
          if (canRemove)
            AdminMoreButton<String>(
              tooltip: 'Manage ad',
              onSelected: (_) async {
                final ok = await adminConfirm(
                  context,
                  title: 'Remove ad?',
                  message: 'The ad stops showing immediately.',
                  confirm: 'Remove',
                  danger: true,
                );
                if (!ok) return;
                await ads.removeAd(ad.id);
                if (context.mounted) adminSnack(context, 'Ad removed');
              },
              itemBuilder: (_) => [
                adminMenuItem(
                  'remove',
                  Icons.block_rounded,
                  'Remove ad',
                  danger: true,
                ),
              ],
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _icon(AdminPalette p) => ColoredBox(
        color: p.softAmber,
        child: Icon(Icons.campaign_rounded, color: p.softAmberText),
      );
}
