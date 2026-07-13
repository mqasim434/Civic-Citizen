import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_constants.dart';
import '../models/app_notification.dart';
import '../routes/app_router.dart';

/// Foreground tray alerts when new Firestore notification docs arrive.
/// Works on Firebase Spark (no Cloud Functions or FCM server push required).
class PushNotificationService {
  PushNotificationService();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;
  String? _boundUserId;
  DateTime _listenerStartedAt = DateTime.now();

  static const _androidChannel = AndroidNotificationChannel(
    'civic_citizen_alerts',
    'Civic Citizen alerts',
    description: 'Lend/borrow, verification, and account notifications',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> bindUser(String? userId) async {
    if (_boundUserId == userId) return;
    _boundUserId = userId;

    await _firestoreSub?.cancel();
    _firestoreSub = null;

    if (userId == null || userId.isEmpty) return;

    _listenerStartedAt = DateTime.now();
    _firestoreSub = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.notificationsSubcollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) return;
      final change =
          snap.docChanges.where((c) => c.type == DocumentChangeType.added);
      for (final c in change) {
        final n = AppNotification.fromFirestore(c.doc);
        if (n.createdAt != null &&
            n.createdAt!.isBefore(
                _listenerStartedAt.subtract(const Duration(seconds: 2)))) {
          continue;
        }
        _showLocal(n.title, n.body, payload: n.contractId ?? n.postId ?? n.type.value);
      }
    });
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    navigatorKey.currentState?.pushNamed(AppConstants.routeNotifications);
  }

  Future<void> _showLocal(String title, String body, {String? payload}) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void dispose() {
    _firestoreSub?.cancel();
  }
}
