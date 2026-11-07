import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/imagekit_config.dart';
import '../constants/app_constants.dart';
import 'imagekit_service.dart';

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

  Future<void> ensureUserIndex({
    required String uid,
    String? displayName,
  }) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection(AppConstants.userIndexCollection).doc(uid).set({
        'displayName': (displayName ?? '').trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Best-effort directory for community post alerts.
    }
  }

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

  Future<String> uploadProfilePhoto({
    required String uid,
    required File image,
  }) {
    return ImageKitService(ImageKitConfig.instance).upload(
      file: image,
      folder: '${AppConstants.profileImagesPath}/$uid',
      fileName: 'avatar.jpg',
    );
  }

  /// Pass null to remove the stored profile photo.
  Future<void> updatePhotoUrl({
    required String uid,
    required String? photoUrl,
  }) async {
    final trimmed = photoUrl?.trim();
    await _users.doc(uid).update({
      if (trimmed == null || trimmed.isEmpty)
        'photoUrl': FieldValue.delete()
      else
        'photoUrl': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
