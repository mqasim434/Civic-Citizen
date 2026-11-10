import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../ads/widgets/boost_post_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../lend_borrow/widgets/lend_borrow_contract_section.dart';
import '../../lost_found/widgets/lost_found_claim_section.dart';
import '../../mutual_confidence/widgets/contact_section.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/post_comments_section.dart';
import '../widgets/post_engagement_bar.dart';
import '../widgets/post_image_gallery.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PostModel?>(
      stream: context.read<PostService>().watchPost(post.id),
      builder: (context, snap) => _PostDetailBody(post: snap.data ?? post),
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody({required this.post});

  final PostModel post;

  Future<void> _share() async {
    final link = AppConstants.sharePostUrl(post.id);
    await SharePlus.instance.share(
      ShareParams(
        text: '${post.title}\n\n${post.description}\n\n$link',
        subject: post.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = context.watch<AuthController>().user?.uid;
    final mine = uid != null && uid == post.authorId;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const WaveHeaderBackground(),
        title: Text(post.title),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: _share,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.isSponsored) SponsoredImpression(post: post),
            if (post.imageUrls.isNotEmpty)
              PostImageGallery(imageUrls: post.imageUrls),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isFulfilled)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.onTertiaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fulfilled — hidden from public feed',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          post.module.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (post.categoryDisplayLabel != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.categoryDisplayLabel!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (post.isSponsored) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Sponsored',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (mine &&
                      !post.isFulfilled &&
                      !post.isSponsored &&
                      !post.isSponsorPaused) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => showBoostPostDialog(context, post),
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Boost post'),
                    ),
                  ],
                  if (mine && post.hasAdHistory) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => showPostInsights(context, post),
                      icon: const Icon(Icons.insights_rounded),
                      label: const Text('View ad insights'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    post.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (post.itemCondition != null &&
                      post.itemCondition!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Condition: ${post.itemCondition}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (post.location != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.location!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  ContactSection(post: post),
                  LendBorrowContractSection(post: post),
                  LostFoundClaimSection(post: post),
                  PostEngagementBar(
                    post: post,
                    showInsights: mine && post.hasAdHistory,
                    onInsights: () => showPostInsights(context, post),
                  ),
                  PostCommentsSection(postId: post.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
