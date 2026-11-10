import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../posts/models/post_model.dart';
import '../../posts/services/post_service.dart';
import '../../posts/views/post_card.dart';
import 'package:civic_citizen/shared/widgets/wave_header.dart';

/// Posts the user has liked.
class FavouritesView extends StatelessWidget {
  const FavouritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = context.watch<AuthController>().user?.uid;

    return Scaffold(
      appBar: AppBar(flexibleSpace: const WaveHeaderBackground(), bottom: const WaveHeaderSpacer(), title: const Text('Favourites')),
      body: uid == null
          ? const Center(child: Text('Please sign in'))
          : StreamBuilder<List<PostModel>>(
              stream: context.read<PostService>().watchFavouritePosts(uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                    child: Text('Could not load your favourites.'),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snap.data!;
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 56,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No favourites yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Posts you like will show up here.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final post = posts[i];
                    return PostCard(
                      key: ValueKey(post.id),
                      post: post,
                      onTap: () => navigatorKey.currentState?.pushNamed(
                        AppConstants.routePostDetail,
                        arguments: post,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
