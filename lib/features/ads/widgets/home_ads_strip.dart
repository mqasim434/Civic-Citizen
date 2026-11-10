import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../models/ad_model.dart';
import '../services/ad_service.dart';
import 'ad_style.dart';
import 'package:civic_citizen/features/auth/controllers/auth_controller.dart';

/// Horizontal sponsored strip for the home feed.
class HomeAdsStrip extends StatelessWidget {
  const HomeAdsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<AdModel>>(
      stream: context.read<AdService>().watchActiveAds(),
      builder: (context, snap) {
        // Don't show users their own ads in the feed.
        final uid = context.read<AuthController>().user?.uid;
        final ads = (snap.data ?? const <AdModel>[])
            .where((a) => a.authorId != uid)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const SponsoredLabel(),
                  const Spacer(),
                  TextButton(
                    onPressed: () => navigatorKey.currentState?.pushNamed(
                      AppConstants.routeCreateAd,
                    ),
                    child: const Text('Run an ad'),
                  ),
                ],
              ),
            ),
            if (ads.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'No live ads yet. Earn points from Daily rewards to promote yours.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              SizedBox(
                height: 148,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: ads.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _AdChip(ad: ads[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdChip extends StatelessWidget {
  const _AdChip({required this.ad});

  final AdModel ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: Card(
        color: AdStyle.background(context),
        shape: AdStyle.cardShape(context),
        child: InkWell(
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (ctx) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad.title, style: theme.textTheme.titleLarge),
                    if (ad.city != null && ad.city!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(ad.city!, style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 12),
                    Text(ad.description),
                    if (ad.contactNumber != null &&
                        ad.contactNumber!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Contact: ${ad.contactNumber}'),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'By ${ad.authorName}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 96,
                    child: ad.imageUrl == null
                        ? ColoredBox(
                            color: theme.colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.campaign_rounded,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          )
                        : Image.network(ad.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ad.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
