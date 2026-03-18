import 'package:flutter/material.dart';

import '../models/post_model.dart';

class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key, required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.imageUrls.isNotEmpty)
              Image.network(
                post.imageUrls.first,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 240,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      if (post.category != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          post.category!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
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
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Contact',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.authorName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      SelectableText(
                        post.contactNumber,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
