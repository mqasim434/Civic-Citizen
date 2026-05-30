import 'package:cloud_firestore/cloud_firestore.dart';

import '../../posts/models/post_model.dart';
import 'contract_status.dart';

/// Digital lend/borrow agreement stored in Firestore.
class LendBorrowContract {
  const LendBorrowContract({
    required this.id,
    required this.postId,
    required this.postModule,
    required this.itemTitle,
    required this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.itemLocation,
    required this.lenderId,
    required this.lenderName,
    required this.borrowerId,
    required this.borrowerName,
    required this.termsText,
    required this.status,
    this.lenderSignatureUrl,
    this.borrowerSignatureUrl,
    this.lenderSignedAt,
    this.borrowerSignedAt,
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

  factory LendBorrowContract.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return LendBorrowContract(
      id: doc.id,
      postId: d['postId'] as String? ?? '',
      postModule: PostModuleX.fromValue(d['postModule'] as String?),
      itemTitle: d['itemTitle'] as String? ?? '',
      itemDescription: d['itemDescription'] as String? ?? '',
      itemCategory: d['itemCategory'] as String?,
      itemCondition: d['itemCondition'] as String?,
      itemLocation: d['itemLocation'] as String?,
      lenderId: d['lenderId'] as String? ?? '',
      lenderName: d['lenderName'] as String? ?? '',
      borrowerId: d['borrowerId'] as String? ?? '',
      borrowerName: d['borrowerName'] as String? ?? '',
      termsText: d['termsText'] as String? ?? '',
      status: ContractStatusX.fromValue(d['status'] as String?),
      lenderSignatureUrl: d['lenderSignatureUrl'] as String?,
      borrowerSignatureUrl: d['borrowerSignatureUrl'] as String?,
      lenderSignedAt: (d['lenderSignedAt'] as Timestamp?)?.toDate(),
      borrowerSignedAt: (d['borrowerSignedAt'] as Timestamp?)?.toDate(),
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
  final String? itemCondition;
  final String? itemLocation;
  final String lenderId;
  final String lenderName;
  final String borrowerId;
  final String borrowerName;
  final String termsText;
  final ContractStatus status;
  final String? lenderSignatureUrl;
  final String? borrowerSignatureUrl;
  final DateTime? lenderSignedAt;
  final DateTime? borrowerSignedAt;
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

  bool involvesUser(String uid) => lenderId == uid || borrowerId == uid;

  bool isLender(String uid) => lenderId == uid;

  bool isBorrower(String uid) => borrowerId == uid;

  bool get qrValid {
    if (qrToken == null || qrToken!.isEmpty) return false;
    if (qrExpiresAt == null) return false;
    return DateTime.now().isBefore(qrExpiresAt!);
  }

  /// JSON payload encoded in the handshake QR code.
  String get qrPayload {
    return '{"v":1,"contractId":"$id","token":"$qrToken"}';
  }
}
