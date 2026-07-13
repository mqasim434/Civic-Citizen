import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/imagekit_config.dart';
import '../constants/app_constants.dart';
import '../models/announcement_poll.dart';
import '../models/app_announcement.dart';
import 'imagekit_service.dart';

/// In-app admin broadcasts — Firestore only (Spark plan, no Cloud Functions).
class AnnouncementService {
  AnnouncementService({ImageKitService? imageKit})
      : _firestore = FirebaseFirestore.instance,
        _imageKit = imageKit ?? ImageKitService(ImageKitConfig.instance);

  final FirebaseFirestore _firestore;
  final ImageKitService _imageKit;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection(AppConstants.announcementsCollection);

  CollectionReference<Map<String, dynamic>> _reads(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.announcementReadsSubcollection);

  Map<String, dynamic> _readBase(String announcementId) => {
        'announcementId': announcementId,
      };

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
      ..._readBase(announcementId),
      'dismissedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> submitFeedback({
    required String userId,
    required String announcementId,
    required bool helpful,
  }) async {
    if (userId.isEmpty || announcementId.isEmpty) return;
    await _reads(userId).doc(announcementId).set({
      ..._readBase(announcementId),
      'dismissedAt': FieldValue.serverTimestamp(),
      'helpful': helpful,
    }, SetOptions(merge: true));
  }

  Future<void> submitPollVote({
    required String userId,
    required String announcementId,
    required String optionId,
  }) async {
    if (userId.isEmpty || announcementId.isEmpty || optionId.isEmpty) return;

    final announcement = await _announcements.doc(announcementId).get();
    if (!announcement.exists) {
      throw Exception('Broadcast not found.');
    }
    final poll = AppAnnouncement.fromFirestore(announcement);
    if (!poll.hasPoll) {
      throw Exception('This broadcast has no poll.');
    }
    if (!poll.pollOptions.any((o) => o.id == optionId)) {
      throw Exception('Invalid poll option.');
    }

    final existing = await _reads(userId).doc(announcementId).get();
    if (existing.data()?['pollOptionId'] != null) {
      throw Exception('You already voted in this poll.');
    }

    await _reads(userId).doc(announcementId).set({
      ..._readBase(announcementId),
      'pollOptionId': optionId,
      'dismissedAt': FieldValue.serverTimestamp(),
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

  Future<String?> getPollVote(String userId, String announcementId) async {
    if (userId.isEmpty || announcementId.isEmpty) return null;
    final doc = await _reads(userId).doc(announcementId).get();
    return doc.data()?['pollOptionId'] as String?;
  }

  /// Helpful feedback + poll totals for admin analytics.
  Future<AnnouncementAudienceStats> getAudienceStats(
    String announcementId,
  ) async {
    if (announcementId.isEmpty) {
      return const AnnouncementAudienceStats();
    }

    final snap = await _firestore
        .collectionGroup(AppConstants.announcementReadsSubcollection)
        .where('announcementId', isEqualTo: announcementId)
        .get();

    var helpfulYes = 0;
    var helpfulNo = 0;
    final pollVotes = <String, int>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final helpful = data['helpful'];
      if (helpful == true) helpfulYes++;
      if (helpful == false) helpfulNo++;

      final optionId = data['pollOptionId'] as String?;
      if (optionId != null && optionId.isNotEmpty) {
        pollVotes[optionId] = (pollVotes[optionId] ?? 0) + 1;
      }
    }

    return AnnouncementAudienceStats(
      totalResponses: snap.docs.length,
      helpfulYes: helpfulYes,
      helpfulNo: helpfulNo,
      pollVotesByOptionId: pollVotes,
    );
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
    String? pollQuestion,
    List<String>? pollOptionTexts,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty || trimmedBody.isEmpty) {
      throw Exception('Title and message are required.');
    }

    List<AnnouncementPollOption>? pollOptions;
    final trimmedQuestion = pollQuestion?.trim();
    if (trimmedQuestion != null && trimmedQuestion.isNotEmpty) {
      final texts = (pollOptionTexts ?? [])
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (texts.length < 2) {
        throw Exception('Polls need a question and at least 2 options.');
      }
      if (texts.length > 5) {
        throw Exception('Polls support up to 5 options.');
      }
      pollOptions = texts
          .map((text) => AnnouncementPollOption(id: _uuid.v4(), text: text))
          .toList();
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
        pollQuestion: trimmedQuestion,
        pollOptions: pollOptions ?? const [],
      ).toCreateMap(
        adminUid: adminUid,
        imageUrl: imageUrl,
        pollQuestion: trimmedQuestion,
        pollOptions: pollOptions,
      ),
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
