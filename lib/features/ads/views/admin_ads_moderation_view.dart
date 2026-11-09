import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../models/ad_model.dart';
import '../services/ad_service.dart';

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
          padding: const EdgeInsets.all(16),
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
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Minimum ad rate',
                          style: theme.textTheme.titleMedium,
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
            Text('All ads', style: theme.textTheme.titleMedium),
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
              ...list.map(
                (ad) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text(ad.title),
                      subtitle: Text(
                        '${ad.authorName} · ${ad.status.value}'
                        '${ad.city != null && ad.city!.isNotEmpty ? ' · ${ad.city}' : ''}'
                        ' · ${ad.pointsSpent} pts',
                      ),
                      trailing: ad.status == AdStatus.removed ||
                              ad.status == AdStatus.stopped
                          ? null
                          : IconButton(
                              tooltip: 'Remove ad',
                              icon: Icon(
                                Icons.block_rounded,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () async {
                                await ads.removeAd(ad.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ad removed'),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
