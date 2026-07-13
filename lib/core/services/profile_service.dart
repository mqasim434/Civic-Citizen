import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

/// User profile updates (display name, ban status reads).
class ProfileService {
  ProfileService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.data());
  }

  static bool isBanned(Map<String, dynamic>? profile) =>
      profile?['isBanned'] == true;

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Display name cannot be empty.');
    }
    await _users.doc(uid).update({
      'displayName': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
