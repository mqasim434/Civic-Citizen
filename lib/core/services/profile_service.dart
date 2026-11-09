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
    String? photoUrl,
  }) async {
    if (uid.isEmpty) return;
    // Keeps the public photo in sync for users who set it before this existed.
    await _syncPublicPhoto(uid, photoUrl);
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
    await _syncPublicPhoto(uid, trimmed);
  }

  /// Copies the profile photo to the user's public trust profile so other
  /// members can see it (users/{uid} is private). Best-effort: skipped if
  /// the user has no public profile yet.
  Future<void> _syncPublicPhoto(String uid, String? photoUrl) async {
    final trimmed = photoUrl?.trim();
    try {
      await _firestore
          .collection(AppConstants.publicTrustCollection)
          .doc(uid)
          .update({
        'photoUrl': trimmed == null || trimmed.isEmpty
            ? FieldValue.delete()
            : trimmed,
      });
    } catch (_) {
      // No public profile yet, or offline.
    }
  }
}
