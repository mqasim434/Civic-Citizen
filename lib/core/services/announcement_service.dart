import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/imagekit_config.dart';
import '../constants/app_constants.dart';
import '../models/app_announcement.dart';
import 'imagekit_service.dart';

/// In-app admin broadcasts — Firestore only (Spark plan, no Cloud Functions).
class AnnouncementService {
  AnnouncementService({ImageKitService? imageKit})
      : _firestore = FirebaseFirestore.instance,
        _imageKit = imageKit ?? ImageKitService(ImageKitConfig.instance);

  final FirebaseFirestore _firestore;
  final ImageKitService _imageKit;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection(AppConstants.announcementsCollection);

  CollectionReference<Map<String, dynamic>> _reads(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.announcementReadsSubcollection);

  /// Active announcements the user has not dismissed yet.
  Future<List<AppAnnouncement>> getPendingForUser(String userId) async {
    if (userId.isEmpty) return [];

    QuerySnapshot<Map<String, dynamic>> activeSnap;
    try {
      activeSnap = await _announcements
          .where('active', isEqualTo: true)
          .get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      debugPrint('Announcements query failed: ${e.code} ${e.message}');
      rethrow;
    }

    final readsSnap = await _reads(userId).get();
    final dismissed = readsSnap.docs.map((d) => d.id).toSet();

    final pending = activeSnap.docs
        .map(AppAnnouncement.fromFirestore)
        .where((a) => !dismissed.contains(a.id))
        .toList();

    pending.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return pending;
  }

  Future<void> dismiss(String userId, String announcementId) async {
    if (userId.isEmpty || announcementId.isEmpty) return;
    await _reads(userId).doc(announcementId).set({
      'dismissedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Save whether the user found a broadcast helpful (also marks as seen).
  Future<void> submitFeedback({
    required String userId,
    required String announcementId,
    required bool helpful,
  }) async {
    if (userId.isEmpty || announcementId.isEmpty) return;
    await _reads(userId).doc(announcementId).set({
      'dismissedAt': FieldValue.serverTimestamp(),
      'helpful': helpful,
    }, SetOptions(merge: true));
  }

  Stream<Set<String>> watchSeenAnnouncementIds(String userId) {
    if (userId.isEmpty) return Stream.value({});
    return _reads(userId).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  Future<bool?> getFeedback(String userId, String announcementId) async {
    if (userId.isEmpty || announcementId.isEmpty) return null;
    final doc = await _reads(userId).doc(announcementId).get();
    return doc.data()?['helpful'] as bool?;
  }

  Stream<List<AppAnnouncement>> watchActiveAnnouncements() {
    return _announcements
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final items =
              snap.docs.map(AppAnnouncement.fromFirestore).toList();
          items.sort((a, b) {
            final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          return items;
        });
  }

  Future<void> create({
    required String adminUid,
    required String title,
    required String body,
    File? imageFile,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty || trimmedBody.isEmpty) {
      throw Exception('Title and message are required.');
    }

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _imageKit.upload(
        file: imageFile,
        folder: AppConstants.announcementImagesPath,
        fileName: 'broadcast_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    await _announcements.add(
      AppAnnouncement(
        id: '',
        title: trimmedTitle,
        body: trimmedBody,
        active: true,
        imageUrl: imageUrl,
      ).toCreateMap(adminUid: adminUid, imageUrl: imageUrl),
    );
  }

  Future<void> setActive(String announcementId, {required bool active}) async {
    await _announcements.doc(announcementId).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppAnnouncement>> watchAllForAdmin() {
    return _announcements
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(AppAnnouncement.fromFirestore).toList());
  }
}
