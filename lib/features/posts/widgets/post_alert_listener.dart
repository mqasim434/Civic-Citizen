import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/profile_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Delivers new-post alerts into the signed-in user's notification inbox.
class PostAlertListener extends StatefulWidget {
  const PostAlertListener({super.key, this.child});

  final Widget? child;

  @override
  State<PostAlertListener> createState() => _PostAlertListenerState();
}

class _PostAlertListenerState extends State<PostAlertListener> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _boundUserId;
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<AuthController>().addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    context.read<AuthController>().removeListener(_sync);
    _sub?.cancel();
    super.dispose();
  }

  void _sync() {
    final user = context.read<AuthController>().user;
    final uid = user?.uid;
    if (uid == _boundUserId) return;
    _boundUserId = uid;
    _sub?.cancel();
    _sub = null;
    if (uid == null || uid.isEmpty) return;

    _startedAt = DateTime.now();
    unawaited(
      context.read<ProfileService>().ensureUserIndex(
            uid: uid,
            displayName: user?.displayName ?? user?.email,
            photoUrl: user?.photoUrl,
          ),
    );

    _sub = FirebaseFirestore.instance
        .collection(AppConstants.postAlertsCollection)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final notifications = context.read<NotificationService>();
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        final authorId = data['authorId'] as String? ?? '';
        if (authorId.isEmpty || authorId == uid) continue;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null &&
            createdAt.isBefore(_startedAt.subtract(const Duration(seconds: 3)))) {
          continue;
        }
        unawaited(
          notifications.ingestPostAlertForUser(
            recipientUserId: uid,
            authorId: authorId,
            authorName: data['authorName'] as String? ?? '',
            postId: data['postId'] as String? ?? change.doc.id,
            postTitle: data['postTitle'] as String? ?? '',
            moduleLabel: data['moduleLabel'] as String? ?? 'community',
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
