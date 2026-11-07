import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/imagekit_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/imagekit_service.dart';
import '../../points/services/points_service.dart';
import '../models/ad_model.dart';

class AdService {
  AdService({
    PointsService? points,
    ImageKitService? imageKit,
  })  : _firestore = FirebaseFirestore.instance,
        _points = points ?? PointsService(),
        _imageKit = imageKit ?? ImageKitService(ImageKitConfig.instance);

  final FirebaseFirestore _firestore;
  final PointsService _points;
  final ImageKitService _imageKit;

  CollectionReference<Map<String, dynamic>> get _ads =>
      _firestore.collection(AppConstants.adsCollection);

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(AppConstants.postsCollection);

  DocumentReference<Map<String, dynamic>> get _adsConfig =>
      _firestore
          .collection(AppConstants.appConfigCollection)
          .doc(AppConstants.adsConfigDoc);

  /// Live min points required to run an ad (admin-configurable).
  Stream<int> watchAdPointsCost() {
    return _adsConfig.snapshots().map(_costFromDoc);
  }

  Future<int> getAdPointsCost() async {
    final snap = await _adsConfig.get();
    return _costFromDoc(snap);
  }

  Future<void> setAdPointsCost(int points) async {
    if (points < 1) throw Exception('Ad rate must be at least 1 point.');
    await _adsConfig.set({
      'minAdPointsCost': points,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  int _costFromDoc(DocumentSnapshot<Map<String, dynamic>> snap) {
    final value = (snap.data()?['minAdPointsCost'] as num?)?.toInt();
    if (value == null || value < 1) return AppConstants.defaultAdPointsCost;
    return value;
  }

  Stream<List<AdModel>> watchActiveAds() {
    return _ads
        .where('status', isEqualTo: AdStatus.active.value)
        .orderBy('createdAt', descending: true)
        .limit(40)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map(AdModel.fromFirestore)
          .where((a) => a.endsAt == null || a.endsAt!.isAfter(now))
          .toList();
    });
  }

  Stream<List<AdModel>> watchAllAdsForAdmin() {
    return _ads
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snap) => snap.docs.map(AdModel.fromFirestore).toList());
  }

  Future<String> createAd({
    required String authorId,
    required String authorName,
    required String title,
    required String description,
    String? contactNumber,
    String? city,
    File? imageFile,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedDesc = description.trim();
    if (trimmedTitle.isEmpty) throw Exception('Enter an ad title.');
    if (trimmedDesc.isEmpty) throw Exception('Enter an ad description.');

    final doc = _ads.doc();
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _imageKit.upload(
        file: imageFile,
        folder: '${AppConstants.adImagesPath}/${doc.id}',
      );
    }

    final cost = await getAdPointsCost();
    final starts = DateTime.now();
    final ends = starts.add(Duration(days: AppConstants.adDurationDays));
    final postRef = _posts.doc();

    await _points.spendPoints(
      uid: authorId,
      amount: cost,
      type: PointLedgerType.adSpend,
      note: 'Ad: $trimmedTitle',
      relatedId: postRef.id,
    );

    await postRef.set({
      'module': 'resources',
      'title': trimmedTitle,
      'description': trimmedDesc,
      'authorId': authorId,
      'authorName': authorName,
      'contactNumber': contactNumber?.trim() ?? '',
      if (city != null && city.trim().isNotEmpty) 'location': city.trim(),
      'imageUrls': imageUrl == null ? <String>[] : [imageUrl],
      'listingStatus': 'active',
      'isInappropriate': false,
      'isStandaloneAd': true,
      'commentCount': 0,
      'likeCount': 0,
      'viewCount': 0,
      'sponsorPointsSpent': cost,
      'sponsoredUntil': Timestamp.fromDate(ends),
      'sponsoredAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await doc.set({
      'title': trimmedTitle,
      'description': trimmedDesc,
      'authorId': authorId,
      'authorName': authorName,
      'contactNumber': contactNumber?.trim(),
      'city': city?.trim(),
      'postId': postRef.id,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': AdStatus.active.value,
      'pointsSpent': cost,
      'startsAt': Timestamp.fromDate(starts),
      'endsAt': Timestamp.fromDate(ends),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// Spends points and marks an existing post as sponsored.
  Future<void> boostPost({
    required String postId,
    required String authorId,
    required String authorName,
    required String title,
  }) async {
    final postRef = _posts.doc(postId);
    final snap = await postRef.get();
    if (!snap.exists) throw Exception('Post not found.');
    final data = snap.data() ?? {};
    if (data['authorId'] != authorId) {
      throw Exception('Only the author can boost this post.');
    }
    final until = (data['sponsoredUntil'] as Timestamp?)?.toDate();
    if (until != null && until.isAfter(DateTime.now())) {
      throw Exception('This post is already sponsored.');
    }

    final cost = await getAdPointsCost();
    final starts = DateTime.now();
    final ends = starts.add(Duration(days: AppConstants.adDurationDays));

    await _points.spendPoints(
      uid: authorId,
      amount: cost,
      type: PointLedgerType.adSpend,
      note: 'Boost: $title',
      relatedId: postId,
    );

    await postRef.update({
      'sponsoredUntil': Timestamp.fromDate(ends),
      'sponsoredAt': FieldValue.serverTimestamp(),
      'sponsorPointsSpent': cost,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _ads.doc().set({
      'title': title,
      'description': data['description'] ?? '',
      'authorId': authorId,
      'authorName': authorName,
      'postId': postId,
      'status': AdStatus.active.value,
      'pointsSpent': cost,
      'startsAt': Timestamp.fromDate(starts),
      'endsAt': Timestamp.fromDate(ends),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAd(String adId, {String? reason}) async {
    final adSnap = await _ads.doc(adId).get();
    final postId = adSnap.data()?['postId'] as String?;
    await _ads.doc(adId).update({
      'status': AdStatus.removed.value,
      if (reason != null && reason.trim().isNotEmpty)
        'removalReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (postId == null || postId.isEmpty) return;
    final postSnap = await _posts.doc(postId).get();
    final standalone = postSnap.data()?['isStandaloneAd'] == true;
    await _posts.doc(postId).update({
      'sponsoredUntil': Timestamp.fromDate(DateTime.now()),
      'updatedAt': FieldValue.serverTimestamp(),
      if (standalone) 'listingStatus': 'fulfilled',
    });
  }
}
