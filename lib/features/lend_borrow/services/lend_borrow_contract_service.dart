import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/imagekit_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/imagekit_service.dart';
import '../../../core/services/notification_service.dart';
import '../../posts/models/post_listing_status.dart';
import '../../posts/models/post_model.dart';
import '../models/contract_status.dart';
import '../models/lend_borrow_contract.dart';

/// Creates lend/borrow contracts, signatures, QR handshake, and GPS logs.
class LendBorrowContractService {
  LendBorrowContractService({NotificationService? notifications})
      : _firestore = FirebaseFirestore.instance,
        _imagekit = ImageKitService(ImageKitConfig.instance),
        _notifications = notifications;

  final FirebaseFirestore _firestore;
  final ImageKitService _imagekit;
  final NotificationService? _notifications;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _contracts =>
      _firestore.collection(AppConstants.contractsCollection);

  /// Resolves lender and borrower UIDs from post type and the counterparty.
  ({String lenderId, String borrowerId}) resolveParties({
    required PostModel post,
    required String counterpartyId,
  }) {
    if (post.module == PostModule.lend) {
      return (lenderId: post.authorId, borrowerId: counterpartyId);
    }
    return (lenderId: counterpartyId, borrowerId: post.authorId);
  }

  String buildTermsText({
    required PostModel post,
    required String lenderName,
    required String borrowerName,
  }) {
    final category = post.categoryDisplayLabel ?? post.category ?? 'General';
    final condition = post.itemCondition?.trim().isNotEmpty == true
        ? post.itemCondition!.trim()
        : 'Not specified';
    final location = post.location?.trim().isNotEmpty == true
        ? post.location!.trim()
        : 'As agreed by both parties';
    final date = DateTime.now().toLocal().toString().split('.').first;

    return '''
LEND / BORROW DIGITAL AGREEMENT

Item: ${post.title}
Category: $category
Condition: $condition
Description: ${post.description}
Location: $location

Lender: $lenderName
Borrower: $borrowerName

Terms:
1. The lender agrees to lend the item described above to the borrower for personal use.
2. The borrower agrees to return the item in the same condition unless otherwise agreed in writing.
3. Both parties confirm they are verified Civic Citizen users (CNIC + admin approval).
4. Physical exchange must be confirmed via in-app QR handshake with GPS coordinates and timestamp.
5. This record is stored in Cloud Firestore and may be used as evidence in case of dispute.

Agreement date: $date
''';
  }

  Stream<LendBorrowContract?> watchContract(String contractId) {
    return _contracts.doc(contractId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return LendBorrowContract.fromFirestore(doc);
    });
  }

  /// Active contract for [postId] involving [userId], if any.
  Stream<LendBorrowContract?> watchActiveContractForPost({
    required String postId,
    required String userId,
  }) {
    return _contracts
        .where('postId', isEqualTo: postId)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      LendBorrowContract? latest;
      for (final doc in snap.docs) {
        final c = LendBorrowContract.fromFirestore(doc);
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

  Future<LendBorrowContract?> getContract(String contractId) async {
    final doc = await _contracts.doc(contractId).get();
    if (!doc.exists || doc.data() == null) return null;
    return LendBorrowContract.fromFirestore(doc);
  }

  /// Counterparty starts agreement from a lend/borrow post.
  Future<String> createContract({
    required PostModel post,
    required String initiatorId,
    required String initiatorName,
  }) async {
    if (post.module != PostModule.lend && post.module != PostModule.borrow) {
      throw Exception('Contracts are only for Lend or Borrow posts.');
    }
    if (post.authorId == initiatorId) {
      throw Exception('The post author cannot start the agreement. The other party must initiate.');
    }

    final postSnap = await _firestore
        .collection(AppConstants.postsCollection)
        .doc(post.id)
        .get();
    final livePost = postSnap.data();
    if (livePost != null &&
        PostListingStatusX.fromValue(livePost['listingStatus'] as String?) ==
            PostListingStatus.fulfilled) {
      throw Exception('This listing is no longer available — exchange already completed.');
    }

    final parties = resolveParties(post: post, counterpartyId: initiatorId);
    final lenderName = post.module == PostModule.lend
        ? post.authorName
        : initiatorName;
    final borrowerName = post.module == PostModule.lend
        ? initiatorName
        : post.authorName;

    final existing = await _contracts
        .where('postId', isEqualTo: post.id)
        .where('participantIds', arrayContains: initiatorId)
        .get();
    for (final doc in existing.docs) {
      final c = LendBorrowContract.fromFirestore(doc);
      if (c.status.isActive &&
          c.lenderId == parties.lenderId &&
          c.borrowerId == parties.borrowerId) {
        throw Exception('An active agreement already exists for this post.');
      }
    }

    final terms = buildTermsText(
      post: post,
      lenderName: lenderName,
      borrowerName: borrowerName,
    );

    final docRef = await _contracts.add({
      'postId': post.id,
      'postModule': post.module.value,
      'itemTitle': post.title,
      'itemDescription': post.description,
      'itemCategory': post.categoryDisplayLabel ?? post.category,
      'itemCondition': post.itemCondition,
      'itemLocation': post.location,
      'lenderId': parties.lenderId,
      'lenderName': lenderName,
      'borrowerId': parties.borrowerId,
      'borrowerName': borrowerName,
      'participantIds': [parties.lenderId, parties.borrowerId],
      'initiatedByUserId': initiatorId,
      'termsText': terms,
      'status': ContractStatus.pendingLenderSignature.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifications?.notifyContractCreated(
      lenderId: parties.lenderId,
      initiatorId: initiatorId,
      initiatorName: initiatorName,
      contractId: docRef.id,
      postId: post.id,
      itemTitle: post.title,
    );
    return docRef.id;
  }

  Future<void> signAsLender({
    required String contractId,
    required String userId,
    required Uint8List signaturePng,
  }) async {
    final contract = await _requireContract(contractId);
    if (contract.lenderId != userId) {
      throw Exception('Only the lender can sign at this step.');
    }
    if (contract.status != ContractStatus.pendingLenderSignature) {
      throw Exception('Lender signature is not required right now.');
    }

    final url = await _uploadSignature(contractId, 'lender', signaturePng);
    await _contracts.doc(contractId).update({
      'lenderSignatureUrl': url,
      'lenderSignedAt': FieldValue.serverTimestamp(),
      'status': ContractStatus.pendingBorrowerSignature.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifications?.notifyContractLenderSigned(
      borrowerId: contract.borrowerId,
      lenderId: contract.lenderId,
      lenderName: contract.lenderName,
      contractId: contractId,
      itemTitle: contract.itemTitle,
    );
  }

  Future<void> signAsBorrower({
    required String contractId,
    required String userId,
    required Uint8List signaturePng,
  }) async {
    final contract = await _requireContract(contractId);
    if (contract.borrowerId != userId) {
      throw Exception('Only the borrower can sign at this step.');
    }
    if (contract.status != ContractStatus.pendingBorrowerSignature) {
      throw Exception('Borrower signature is not required right now.');
    }

    final url = await _uploadSignature(contractId, 'borrower', signaturePng);
    final token = _uuid.v4();
    final expires = DateTime.now().add(
      const Duration(hours: AppConstants.contractQrValidityHours),
    );

    await _contracts.doc(contractId).update({
      'borrowerSignatureUrl': url,
      'borrowerSignedAt': FieldValue.serverTimestamp(),
      'status': ContractStatus.readyForHandshake.value,
      'qrToken': token,
      'qrExpiresAt': Timestamp.fromDate(expires),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifications?.notifyContractBorrowerSigned(
      lenderId: contract.lenderId,
      borrowerId: contract.borrowerId,
      borrowerName: contract.borrowerName,
      contractId: contractId,
      itemTitle: contract.itemTitle,
    );
  }

  /// Lender refreshes QR token before meetup (optional).
  Future<void> refreshQrToken({
    required String contractId,
    required String userId,
  }) async {
    final contract = await _requireContract(contractId);
    if (contract.lenderId != userId) {
      throw Exception('Only the lender can refresh the QR code.');
    }
    if (contract.status != ContractStatus.readyForHandshake) {
      throw Exception('QR is only available after both parties have signed.');
    }

    final token = _uuid.v4();
    final expires = DateTime.now().add(
      const Duration(hours: AppConstants.contractQrValidityHours),
    );
    await _contracts.doc(contractId).update({
      'qrToken': token,
      'qrExpiresAt': Timestamp.fromDate(expires),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Borrower scans lender QR; logs GPS + timestamp and completes contract.
  Future<void> completeHandshake({
    required String contractId,
    required String token,
    required String scannerUserId,
  }) async {
    final contract = await _requireContract(contractId);
    if (contract.borrowerId != scannerUserId) {
      throw Exception('Only the borrower can scan to confirm the exchange.');
    }
    if (contract.status != ContractStatus.readyForHandshake) {
      throw Exception('This agreement is not ready for handshake.');
    }
    if (contract.qrToken != token) {
      throw Exception('Invalid QR code.');
    }
    if (!contract.qrValid) {
      throw Exception('QR code has expired. Ask the lender to refresh it.');
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
    final contractRef = _contracts.doc(contractId);
    batch.update(contractRef, {
      'status': ContractStatus.completed.value,
      'handshakeLatitude': position.latitude,
      'handshakeLongitude': position.longitude,
      if (address != null && address.isNotEmpty) 'handshakeAddress': address,
      'handshakeScannedByUserId': scannerUserId,
      'handshakeAt': FieldValue.serverTimestamp(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(contractRef.collection('handshake_logs').doc(), {
      'contractId': contractId,
      'postId': contract.postId,
      'lenderId': contract.lenderId,
      'borrowerId': contract.borrowerId,
      'scannedByUserId': scannerUserId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      if (address != null && address.isNotEmpty) 'address': address,
      'recordedAt': FieldValue.serverTimestamp(),
    });

    final postRef = _firestore
        .collection(AppConstants.postsCollection)
        .doc(contract.postId);
    batch.update(postRef, {
      'listingStatus': PostListingStatus.fulfilled.value,
      'fulfilledAt': FieldValue.serverTimestamp(),
      'completedContractId': contractId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _notifications?.notifyContractCompleted(
      lenderId: contract.lenderId,
      borrowerId: contract.borrowerId,
      contractId: contractId,
      itemTitle: contract.itemTitle,
    );
  }
  Stream<List<LendBorrowContract>> watchCompletedContractsForUser(String userId) {
    return _contracts
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(LendBorrowContract.fromFirestore)
          .where((c) => c.status == ContractStatus.completed)
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

  /// Parse QR JSON from scanner.
  ({String contractId, String token})? parseQrPayload(String raw) {
    try {
      final data = jsonDecode(raw.trim()) as Map<String, dynamic>;
      final contractId = data['contractId'] as String?;
      final token = data['token'] as String?;
      if (contractId == null ||
          contractId.isEmpty ||
          token == null ||
          token.isEmpty) {
        return null;
      }
      return (contractId: contractId, token: token);
    } catch (_) {
      return null;
    }
  }

  Future<LendBorrowContract> _requireContract(String contractId) async {
    final contract = await getContract(contractId);
    if (contract == null) {
      throw Exception('Agreement not found.');
    }
    return contract;
  }

  Future<String> _uploadSignature(
    String contractId,
    String role,
    Uint8List pngBytes,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/contract_${contractId}_$role.png');
    await file.writeAsBytes(pngBytes);
    return _imagekit.upload(
      file: file,
      folder: '${AppConstants.contractSignaturesPath}/$contractId',
      fileName: '$role.png',
    );
  }

  Future<Position> _currentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to log the exchange.');
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Turn on location services to complete the handshake.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }
}
