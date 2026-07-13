import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../mutual_confidence/services/trust_profile_service.dart';
import '../../posts/models/post_listing_status.dart';
import '../../posts/models/post_model.dart';
import '../models/claim_status.dart';
import '../models/lost_found_claim.dart';

/// Lost/found recovery claims with QR handshake and GPS logging.
class LostFoundClaimService {
  LostFoundClaimService({
    NotificationService? notifications,
    TrustProfileService? trustProfiles,
  })  : _firestore = FirebaseFirestore.instance,
        _notifications = notifications,
        _trustProfiles = trustProfiles;

  final FirebaseFirestore _firestore;
  final NotificationService? _notifications;
  final TrustProfileService? _trustProfiles;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection(AppConstants.lostFoundClaimsCollection);

  ({String ownerId, String ownerName, String finderId, String finderName})
      resolveParties({
    required PostModel post,
    required String counterpartyId,
    required String counterpartyName,
  }) {
    if (post.module == PostModule.lost) {
      return (
        ownerId: post.authorId,
        ownerName: post.authorName,
        finderId: counterpartyId,
        finderName: counterpartyName,
      );
    }
    return (
      ownerId: counterpartyId,
      ownerName: counterpartyName,
      finderId: post.authorId,
      finderName: post.authorName,
    );
  }

  String buildSummaryText({
    required PostModel post,
    required String ownerName,
    required String finderName,
  }) {
    final category = post.categoryDisplayLabel ?? post.category ?? 'General';
    final location = post.location?.trim().isNotEmpty == true
        ? post.location!.trim()
        : 'As agreed by both parties';
    final action = post.module == PostModule.lost
        ? 'return of lost item to owner'
        : 'return of found item to rightful owner';

    return '''
LOST / FOUND RECOVERY RECORD

Item: ${post.title}
Category: $category
Description: ${post.description}
Location: $location

Owner: $ownerName
Finder: $finderName

Both parties confirm the $action via in-app QR scan with GPS coordinates and timestamp.
This record is stored in Cloud Firestore for community trust and dispute resolution.
''';
  }

  Stream<LostFoundClaim?> watchClaim(String claimId) {
    return _claims.doc(claimId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return LostFoundClaim.fromFirestore(doc);
    });
  }

  Stream<LostFoundClaim?> watchActiveClaimForPost({
    required String postId,
    required String userId,
  }) {
    return _claims
        .where('postId', isEqualTo: postId)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      LostFoundClaim? latest;
      for (final doc in snap.docs) {
        final c = LostFoundClaim.fromFirestore(doc);
        if (!c.status.isActive) continue;
        if (latest == null ||
            (c.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).isAfter(
              latest.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            )) {
          latest = c;
        }
      }
      return latest;
    });
  }

  Future<LostFoundClaim?> getClaim(String claimId) async {
    final doc = await _claims.doc(claimId).get();
    if (!doc.exists || doc.data() == null) return null;
    return LostFoundClaim.fromFirestore(doc);
  }

  Future<String> createClaim({
    required PostModel post,
    required String initiatorId,
    required String initiatorName,
  }) async {
    if (post.module != PostModule.lost && post.module != PostModule.found) {
      throw Exception('Claims are only for Lost or Found posts.');
    }
    if (post.authorId == initiatorId) {
      throw Exception(
        'The post author cannot start the claim. The other party must initiate.',
      );
    }

    final postSnap = await _firestore
        .collection(AppConstants.postsCollection)
        .doc(post.id)
        .get();
    final livePost = postSnap.data();
    if (livePost != null &&
        PostListingStatusX.fromValue(livePost['listingStatus'] as String?) ==
            PostListingStatus.fulfilled) {
      throw Exception('This listing is no longer available — recovery already confirmed.');
    }

    final parties = resolveParties(
      post: post,
      counterpartyId: initiatorId,
      counterpartyName: initiatorName,
    );

    final existing = await _claims
        .where('postId', isEqualTo: post.id)
        .where('participantIds', arrayContains: initiatorId)
        .get();
    for (final doc in existing.docs) {
      final c = LostFoundClaim.fromFirestore(doc);
      if (c.status.isActive &&
          c.ownerId == parties.ownerId &&
          c.finderId == parties.finderId) {
        throw Exception('An active recovery claim already exists for this post.');
      }
    }

    final summary = buildSummaryText(
      post: post,
      ownerName: parties.ownerName,
      finderName: parties.finderName,
    );

    final docRef = await _claims.add({
      'postId': post.id,
      'postModule': post.module.value,
      'itemTitle': post.title,
      'itemDescription': post.description,
      'itemCategory': post.categoryDisplayLabel ?? post.category,
      'itemLocation': post.location,
      'ownerId': parties.ownerId,
      'ownerName': parties.ownerName,
      'finderId': parties.finderId,
      'finderName': parties.finderName,
      'participantIds': [parties.ownerId, parties.finderId],
      'qrDisplayUserId': post.authorId,
      'qrScannerUserId': initiatorId,
      'initiatedByUserId': initiatorId,
      'summaryText': summary,
      'status': ClaimStatus.pendingConfirm.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifications?.notifyClaimCreated(
      postAuthorId: post.authorId,
      initiatorId: initiatorId,
      initiatorName: initiatorName,
      claimId: docRef.id,
      postId: post.id,
      itemTitle: post.title,
    );
    return docRef.id;
  }

  /// Post author confirms they are ready to meet and issue QR.
  Future<void> confirmClaim({
    required String claimId,
    required String userId,
  }) async {
    final claim = await _requireClaim(claimId);
    if (claim.qrDisplayUserId != userId) {
      throw Exception('Only the post author can confirm this recovery claim.');
    }
    if (claim.status != ClaimStatus.pendingConfirm) {
      throw Exception('This claim is not awaiting confirmation.');
    }

    final token = _uuid.v4();
    final expires = DateTime.now().add(
      const Duration(hours: AppConstants.contractQrValidityHours),
    );

    await _claims.doc(claimId).update({
      'status': ClaimStatus.readyForHandshake.value,
      'qrToken': token,
      'qrExpiresAt': Timestamp.fromDate(expires),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifications?.notifyClaimReadyForHandshake(
      qrScannerUserId: claim.qrScannerUserId,
      qrDisplayUserId: claim.qrDisplayUserId,
      claimId: claimId,
      itemTitle: claim.itemTitle,
    );
  }

  Future<void> refreshQrToken({
    required String claimId,
    required String userId,
  }) async {
    final claim = await _requireClaim(claimId);
    if (claim.qrDisplayUserId != userId) {
      throw Exception('Only the post author can refresh the QR code.');
    }
    if (claim.status != ClaimStatus.readyForHandshake) {
      throw Exception('QR is only available after the claim is confirmed.');
    }

    final token = _uuid.v4();
    final expires = DateTime.now().add(
      const Duration(hours: AppConstants.contractQrValidityHours),
    );
    await _claims.doc(claimId).update({
      'qrToken': token,
      'qrExpiresAt': Timestamp.fromDate(expires),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeHandshake({
    required String claimId,
    required String token,
    required String scannerUserId,
  }) async {
    final claim = await _requireClaim(claimId);
    if (claim.qrScannerUserId != scannerUserId) {
      throw Exception('Only the other party can scan to confirm recovery.');
    }
    if (claim.status != ClaimStatus.readyForHandshake) {
      throw Exception('This claim is not ready for QR confirmation.');
    }
    if (claim.qrToken != token) {
      throw Exception('Invalid QR code.');
    }
    if (!claim.qrValid) {
      throw Exception('QR code has expired. Ask the post author to refresh it.');
    }

    final position = await _currentPosition();
    String? address;
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        address = [p.street, p.locality, p.administrativeArea]
            .where((e) => e != null && e.trim().isNotEmpty)
            .join(', ');
      }
    } catch (_) {}

    final batch = _firestore.batch();
    final claimRef = _claims.doc(claimId);
    batch.update(claimRef, {
      'status': ClaimStatus.completed.value,
      'handshakeLatitude': position.latitude,
      'handshakeLongitude': position.longitude,
      if (address != null && address.isNotEmpty) 'handshakeAddress': address,
      'handshakeScannedByUserId': scannerUserId,
      'handshakeAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(claimRef.collection('handshake_logs').doc(), {
      'claimId': claimId,
      'postId': claim.postId,
      'ownerId': claim.ownerId,
      'finderId': claim.finderId,
      'scannedByUserId': scannerUserId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      if (address != null && address.isNotEmpty) 'address': address,
      'recordedAt': FieldValue.serverTimestamp(),
    });

    final postRef =
        _firestore.collection(AppConstants.postsCollection).doc(claim.postId);
    batch.update(postRef, {
      'listingStatus': PostListingStatus.fulfilled.value,
      'fulfilledAt': FieldValue.serverTimestamp(),
      'completedContractId': claimId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _trustProfiles?.incrementCompletedRecoveriesForBoth(
      userA: claim.ownerId,
      userB: claim.finderId,
    );

    await _notifications?.notifyClaimCompleted(
      ownerId: claim.ownerId,
      finderId: claim.finderId,
      claimId: claimId,
      itemTitle: claim.itemTitle,
    );
  }

  Stream<List<LostFoundClaim>> watchCompletedClaimsForUser(String userId) {
    return _claims
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(LostFoundClaim.fromFirestore)
          .where((c) => c.status == ClaimStatus.completed)
          .toList();
      list.sort((a, b) {
        final at = a.completedAt ?? a.handshakeAt ?? a.createdAt;
        final bt = b.completedAt ?? b.handshakeAt ?? b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  ({String claimId, String token})? parseQrPayload(String raw) {
    try {
      final data = jsonDecode(raw.trim()) as Map<String, dynamic>;
      if (data['type'] != 'lost_found_claim') return null;
      final claimId = data['claimId'] as String?;
      final token = data['token'] as String?;
      if (claimId == null ||
          claimId.isEmpty ||
          token == null ||
          token.isEmpty) {
        return null;
      }
      return (claimId: claimId, token: token);
    } catch (_) {
      return null;
    }
  }

  Future<LostFoundClaim> _requireClaim(String claimId) async {
    final claim = await getClaim(claimId);
    if (claim == null) throw Exception('Recovery claim not found.');
    return claim;
  }

  Future<Position> _currentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to log the recovery.');
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Turn on location services to complete confirmation.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }
}
