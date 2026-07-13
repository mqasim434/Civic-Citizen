import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/public_trust_profile.dart';

/// Maintains public trust cards for community members.
class TrustProfileService {
  TrustProfileService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection(AppConstants.publicTrustCollection);

  Stream<PublicTrustProfile?> watchProfile(String userId) {
    if (userId.isEmpty) {
      return Stream.value(null);
    }
    return _profiles.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PublicTrustProfile.fromFirestore(doc);
    });
  }

  Future<PublicTrustProfile?> getProfile(String userId) async {
    if (userId.isEmpty) return null;
    final doc = await _profiles.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PublicTrustProfile.fromFirestore(doc);
  }

  Future<void> ensureProfile({
    required String userId,
    required String displayName,
    String verificationStatus = 'pending',
  }) async {
    if (userId.isEmpty) return;
    final ref = _profiles.doc(userId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.update({
        if (displayName.trim().isNotEmpty) 'displayName': displayName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await ref.set({
      'displayName': displayName.trim().isEmpty ? 'Community member' : displayName.trim(),
      'verificationStatus': verificationStatus,
      'completedExchanges': 0,
      'completedRecoveries': 0,
      'memberSince': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markVerified({
    required String userId,
    required String displayName,
  }) async {
    await ensureProfile(
      userId: userId,
      displayName: displayName,
      verificationStatus: 'verified',
    );
    await _profiles.doc(userId).update({
      'verificationStatus': 'verified',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementCompletedExchanges(String userId) async {
    await _incrementCounter(userId, field: 'completedExchanges');
  }

  Future<void> incrementCompletedRecoveries(String userId) async {
    await _incrementCounter(userId, field: 'completedRecoveries');
  }

  Future<void> incrementCompletedExchangesForBoth({
    required String userA,
    required String userB,
  }) async {
    await Future.wait([
      incrementCompletedExchanges(userA),
      incrementCompletedExchanges(userB),
    ]);
  }

  Future<void> incrementCompletedRecoveriesForBoth({
    required String userA,
    required String userB,
  }) async {
    await Future.wait([
      incrementCompletedRecoveries(userA),
      incrementCompletedRecoveries(userB),
    ]);
  }

  Future<void> _incrementCounter(
    String userId, {
    required String field,
  }) async {
    if (userId.isEmpty) return;
    final ref = _profiles.doc(userId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'displayName': 'Community member',
        'verificationStatus': 'pending',
        'completedExchanges': field == 'completedExchanges' ? 1 : 0,
        'completedRecoveries': field == 'completedRecoveries' ? 1 : 0,
        'memberSince': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await ref.update({
      field: FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
