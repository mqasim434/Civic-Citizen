import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../posts/models/post_model.dart';
import 'claim_status.dart';

/// Lost/found recovery claim with QR + GPS confirmation.
class LostFoundClaim {
  const LostFoundClaim({
    required this.id,
    required this.postId,
    required this.postModule,
    required this.itemTitle,
    required this.itemDescription,
    this.itemCategory,
    this.itemLocation,
    required this.ownerId,
    required this.ownerName,
    required this.finderId,
    required this.finderName,
    required this.qrDisplayUserId,
    required this.qrScannerUserId,
    required this.status,
    this.summaryText,
    this.qrToken,
    this.qrExpiresAt,
    this.handshakeLatitude,
    this.handshakeLongitude,
    this.handshakeAddress,
    this.handshakeScannedByUserId,
    this.handshakeAt,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory LostFoundClaim.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return LostFoundClaim(
      id: doc.id,
      postId: d['postId'] as String? ?? '',
      postModule: PostModuleX.fromValue(d['postModule'] as String?),
      itemTitle: d['itemTitle'] as String? ?? '',
      itemDescription: d['itemDescription'] as String? ?? '',
      itemCategory: d['itemCategory'] as String?,
      itemLocation: d['itemLocation'] as String?,
      ownerId: d['ownerId'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? '',
      finderId: d['finderId'] as String? ?? '',
      finderName: d['finderName'] as String? ?? '',
      qrDisplayUserId: d['qrDisplayUserId'] as String? ?? '',
      qrScannerUserId: d['qrScannerUserId'] as String? ?? '',
      status: ClaimStatusX.fromValue(d['status'] as String?),
      summaryText: d['summaryText'] as String?,
      qrToken: d['qrToken'] as String?,
      qrExpiresAt: (d['qrExpiresAt'] as Timestamp?)?.toDate(),
      handshakeLatitude: (d['handshakeLatitude'] as num?)?.toDouble(),
      handshakeLongitude: (d['handshakeLongitude'] as num?)?.toDouble(),
      handshakeAddress: d['handshakeAddress'] as String?,
      handshakeScannedByUserId: d['handshakeScannedByUserId'] as String?,
      handshakeAt: (d['handshakeAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String postId;
  final PostModule postModule;
  final String itemTitle;
  final String itemDescription;
  final String? itemCategory;
  final String? itemLocation;
  final String ownerId;
  final String ownerName;
  final String finderId;
  final String finderName;
  final String qrDisplayUserId;
  final String qrScannerUserId;
  final ClaimStatus status;
  final String? summaryText;
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final double? handshakeLatitude;
  final double? handshakeLongitude;
  final String? handshakeAddress;
  final String? handshakeScannedByUserId;
  final DateTime? handshakeAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  bool involvesUser(String uid) => ownerId == uid || finderId == uid;

  bool isQrDisplayUser(String uid) => qrDisplayUserId == uid;

  bool isQrScanner(String uid) => qrScannerUserId == uid;

  bool get qrValid {
    if (qrToken == null || qrToken!.isEmpty) return false;
    if (qrExpiresAt == null) return false;
    return DateTime.now().isBefore(qrExpiresAt!);
  }

  String get qrPayload => jsonEncode({
        'v': 1,
        'type': 'lost_found_claim',
        'claimId': id,
        'token': qrToken,
      });

  String roleLabelFor(String uid) {
    if (postModule == PostModule.lost) {
      if (uid == ownerId) return 'Item owner (lost post)';
      if (uid == finderId) return 'Finder / return helper';
    } else {
      if (uid == finderId) return 'Finder (found post)';
      if (uid == ownerId) return 'Rightful owner';
    }
    return 'Participant';
  }
}
