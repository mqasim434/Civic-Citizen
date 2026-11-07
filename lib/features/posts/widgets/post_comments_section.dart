import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/network_status.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/post_comment.dart';
import '../services/comment_service.dart';

class PostCommentsSection extends StatefulWidget {
  const PostCommentsSection({
    super.key,
    required this.postId,
    this.onOptimisticAdd,
    this.onOptimisticRevert,
  });

  final String postId;
  final VoidCallback? onOptimisticAdd;
  final VoidCallback? onOptimisticRevert;

  @override
  State<PostCommentsSection> createState() => _PostCommentsSectionState();
}

class _PostCommentsSectionState extends State<PostCommentsSection> {
  final _controller = TextEditingController();
  final List<_PendingComment> _pending = [];
  Set<String> _remoteIds = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = context.read<AuthController>().user;
    if (user == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!await NetworkStatus.isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(NetworkStatus.offlineMessage)),
      );
      return;
    }
    if (!mounted) return;

    final local = _PendingComment(
      comment: PostComment(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        postId: widget.postId,
        authorId: user.uid,
        authorName: user.displayName ?? user.email ?? 'Citizen',
        text: text,
        createdAt: DateTime.now(),
      ),
      existingIds: Set<String>.from(_remoteIds),
    );
    setState(() {
      _pending.add(local);
      _controller.clear();
    });
    widget.onOptimisticAdd?.call();

    try {
      await context.read<CommentService>().addComment(
            postId: widget.postId,
            authorId: user.uid,
            authorName: local.comment.authorName,
            text: text,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _pending.remove(local));
      widget.onOptimisticRevert?.call();
      _controller.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NetworkStatus.isOfflineError(e)
                ? NetworkStatus.offlineMessage
                : '$e'.replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthController>().user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Text('Comments', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        StreamBuilder<List<PostComment>>(
          stream: context.read<CommentService>().watchComments(widget.postId),
          builder: (context, snap) {
            final remote = snap.data ?? [];
            _remoteIds = remote.map((c) => c.id).toSet();
            _pending.removeWhere(
              (local) => remote.any(
                (saved) =>
                    !local.existingIds.contains(saved.id) &&
                    saved.authorId == local.comment.authorId &&
                    saved.text == local.comment.text,
              ),
            );
            final comments = [
              ...remote,
              ..._pending.map((item) => item.comment),
            ];
            if (comments.isEmpty) {
              return Text(
                'No comments yet. Start the discussion.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = comments[i];
                final canDelete = user != null && user.uid == c.authorId;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(
                        c.authorName.isNotEmpty
                            ? c.authorName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.authorName,
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(c.text),
                        ],
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => context
                            .read<CommentService>()
                            .deleteComment(
                              postId: widget.postId,
                              commentId: c.id,
                            ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Write a comment…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _PendingComment {
  const _PendingComment({required this.comment, required this.existingIds});

  final PostComment comment;
  final Set<String> existingIds;
}
