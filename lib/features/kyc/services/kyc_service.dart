import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/config/imagekit_config.dart';
import '../../../core/services/imagekit_service.dart';
import '../models/kyc_status.dart';

/// Handles KYC uploads and user profile in Firestore.
class KycService {
  final _picker = ImagePicker();
  KycService()
      : _firestore = FirebaseFirestore.instance,
        _imagekit = ImageKitService(ImageKitConfig.instance);

  final FirebaseFirestore _firestore;
  final ImageKitService _imagekit;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  /// Pick image from camera or gallery.
  Future<File?> pickImage({required bool fromCamera}) async {
    final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// Detect if image contains a face (for selfie liveness).
  Future<bool> detectFace(File image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: false,
        enableContours: false,
        minFaceSize: 0.15,
      ),
    );
    try {
      final faces = await detector.processImage(inputImage);
      await detector.close();
      return faces.isNotEmpty;
    } catch (_) {
      await detector.close();
      return false;
    }
  }

  /// Upload CNIC image and save path to user document.
  Future<String> uploadCnic(String uid, File image, {required String side}) async {
    return _imagekit.upload(
      file: image,
      folder: '${AppConstants.cnicStoragePath}/$uid/$side',
    );
  }

  /// KYC documents submitted (awaiting admin verification or already decided).
  static bool hasSubmittedKyc(Map<String, dynamic>? profile) {
    return profile != null && profile['kycSubmittedAt'] != null;
  }

  @Deprecated('Use hasSubmittedKyc')
  static bool isKycComplete(Map<String, dynamic>? profile) => hasSubmittedKyc(profile);

  /// Upload selfie image and save path to user document.
  Future<String> uploadSelfie(String uid, File image) async {
    return _imagekit.upload(
      file: image,
      folder: '${AppConstants.selfieStoragePath}/$uid',
    );
  }

  /// Create or update user profile with KYC data.
  Future<void> saveKycProfile({
    required String uid,
    required String displayName,
    required String email,
    required String cnicFrontImageUrl,
    required String cnicBackImageUrl,
    required String selfieImageUrl,
  }) async {
    await _users.doc(uid).set({
      'displayName': displayName,
      'email': email,
      'cnicFrontImageUrl': cnicFrontImageUrl,
      'cnicBackImageUrl': cnicBackImageUrl,
      'cnicImageUrl': cnicFrontImageUrl,
      'selfieImageUrl': selfieImageUrl,
      'verificationStatus': KycStatus.pending.name,
      'kycSubmittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user KYC profile.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  /// Stream user profile for verification status.
  Stream<Map<String, dynamic>?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.data());
  }
}
