import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/emailjs_service.dart';
import '../../posts/models/post_model.dart';

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

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(AppConstants.postsCollection);

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

  /// Stream all posts for moderation, optionally filtered by module.
  Stream<List<PostModel>> watchPosts({PostModule? module}) {
    final Query<Map<String, dynamic>> q = module != null
        ? _posts.where('module', isEqualTo: module.value).orderBy('createdAt', descending: true)
        : _posts.orderBy('createdAt', descending: true);
    return q.snapshots().map(
      (snap) => snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
    );
  }

  /// Mark or unmark a post as inappropriate for moderation.
  Future<void> markPostInappropriate(
    String postId, {
    required bool inappropriate,
    String? reason,
  }) async {
    await _posts.doc(postId).update({
      'isInappropriate': inappropriate,
      if (inappropriate && reason != null && reason.trim().isNotEmpty)
        'inappropriateReason': reason.trim(),
      if (!inappropriate) 'inappropriateReason': FieldValue.delete(),
      'moderatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently delete any post as admin.
  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  /// Stream all users for admin user management.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    return _users.orderBy('updatedAt', descending: true).snapshots();
  }

  /// Ban or unban a user profile in Firestore.
  Future<void> setUserBanned(
    String uid, {
    required bool banned,
    String? reason,
  }) async {
    await _users.doc(uid).set({
      'isBanned': banned,
      if (banned && reason != null && reason.trim().isNotEmpty)
        'banReason': reason.trim(),
      if (!banned) 'banReason': FieldValue.delete(),
      'bannedAt': banned ? FieldValue.serverTimestamp() : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Delete user profile and all posts authored by that user.
  Future<void> deleteUserProfile(String uid) async {
    final postsSnap = await _posts.where('authorId', isEqualTo: uid).get();
    final batch = _firestore.batch();
    for (final doc in postsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_users.doc(uid));
    await batch.commit();
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
