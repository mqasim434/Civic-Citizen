import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/kyc_service.dart';

/// KYC flow state and actions.
class KycController extends ChangeNotifier {
  KycController(this._kycService);

  final KycService _kycService;

  File? _cnicImage;
  File? get cnicImage => _cnicImage;
  bool get hasCnic => _cnicImage != null;

  File? _selfieImage;
  File? get selfieImage => _selfieImage;
  bool get hasSelfie => _selfieImage != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Pick CNIC from camera or gallery.
  Future<bool> pickCnic({required bool fromCamera}) async {
    _setLoading(true);
    _error = null;
    try {
      final file = await _kycService.pickImage(fromCamera: fromCamera);
      if (file != null) {
        _cnicImage = file;
        _setLoading(false);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
    notifyListeners();
    return false;
  }

  /// Capture selfie (camera only) and verify face is present.
  Future<bool> captureSelfie() async {
    _setLoading(true);
    _error = null;
    try {
      final file = await _kycService.pickImage(fromCamera: true);
      if (file == null) {
        _setLoading(false);
        notifyListeners();
        return false;
      }
      final hasFace = await _kycService.detectFace(file);
      if (!hasFace) {
        _error = 'No face detected. Please take a clear selfie with your face visible.';
        _setLoading(false);
        notifyListeners();
        return false;
      }
      _selfieImage = file;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Submit KYC (upload images and save profile).
  Future<bool> submitKyc({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    if (_cnicImage == null || _selfieImage == null) return false;
    _setLoading(true);
    _error = null;
    try {
      final cnicUrl = await _kycService.uploadCnic(uid, _cnicImage!);
      final selfieUrl = await _kycService.uploadSelfie(uid, _selfieImage!);
      await _kycService.saveKycProfile(
        uid: uid,
        displayName: displayName,
        email: email,
        cnicImageUrl: cnicUrl,
        selfieImageUrl: selfieUrl,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void clearImages() {
    _cnicImage = null;
    _selfieImage = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
