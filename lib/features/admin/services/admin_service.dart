import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/emailjs_service.dart';

/// Admin access: create document [adminsCollection]/[adminUid] in Firebase Console only.
class AdminService {
  AdminService({EmailJsService? emailJs})
      : _firestore = FirebaseFirestore.instance,
        _emailJs = emailJs ?? EmailJsService();

  final FirebaseFirestore _firestore;
  final EmailJsService _emailJs;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _admins =>
      _firestore.collection(AppConstants.adminsCollection);

  /// True if [uid] has an admin document (managed only in Firebase).
  Future<bool> isAdmin(String uid) async {
    final doc = await _admins.doc(uid).get();
    return doc.exists;
  }

  /// Users waiting for identity verification.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingVerifications() {
    return _users
        .where('verificationStatus', isEqualTo: 'pending')
        .orderBy('kycSubmittedAt', descending: true)
        .snapshots();
  }

  Future<void> markVerified(String uid) async {
    final snap = await _users.doc(uid).get();
    final data = snap.data();
    final email = data?['email'] as String? ?? '';
    final name = data?['displayName'] as String? ?? '';

    await _users.doc(uid).update({
      'verificationStatus': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _emailJs.sendVerificationResult(
      toEmail: email,
      userName: name,
      verified: true,
    );
  }

  Future<void> markRejected(String uid, {String? reason}) async {
    final snap = await _users.doc(uid).get();
    final data = snap.data();
    final email = data?['email'] as String? ?? '';
    final name = data?['displayName'] as String? ?? '';

    await _users.doc(uid).update({
      'verificationStatus': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _emailJs.sendVerificationResult(
      toEmail: email,
      userName: name,
      verified: false,
      rejectionReason: reason,
    );
  }
}
