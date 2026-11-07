import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Delivers new-event alerts into the signed-in user's notification inbox.
class EventAlertListener extends StatefulWidget {
  const EventAlertListener({super.key, this.child});

  final Widget? child;

  @override
  State<EventAlertListener> createState() => _EventAlertListenerState();
}

class _EventAlertListenerState extends State<EventAlertListener> {
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
    _sub = FirebaseFirestore.instance
        .collection(AppConstants.eventAlertsCollection)
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
        if (authorId == uid) continue;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null &&
            createdAt.isBefore(_startedAt.subtract(const Duration(seconds: 3)))) {
          continue;
        }
        final title = data['title'] as String? ?? 'Community event';
        final city = data['city'] as String? ?? '';
        final eventId = data['eventId'] as String? ?? '';
        unawaited(
          notifications.notifyUser(
            recipientUserId: uid,
            type: AppNotificationType.eventPublished,
            title: 'New event: $title',
            body: city.isEmpty
                ? 'A community event was just published.'
                : 'Taking place in $city.',
            actorUserId: authorId,
            contractId: eventId,
            routeName: AppConstants.routeEvents,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
