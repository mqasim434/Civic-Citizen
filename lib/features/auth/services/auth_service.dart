import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

/// Handles Firebase Authentication for Civic Citizen.
/// When Firebase is not initialized, auth is no-op so you can view UI screens.
class AuthService {
  AuthService() : _auth = _getAuth();

  static FirebaseAuth? _getAuth() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  final FirebaseAuth? _auth;
  bool get _isFirebaseReady => _auth != null;

  Stream<UserModel?> get authStateChanges {
    if (!_isFirebaseReady) return Stream.value(null);
    return _auth!.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel.fromFirebase(user);
    });
  }

  UserModel? get currentUser {
    if (!_isFirebaseReady) return null;
    final user = _auth!.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebase(user);
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_isFirebaseReady) {
      throw Exception('Firebase is not configured. Add google-services.json and uncomment Firebase.initializeApp() in main.dart.');
    }
    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    if (displayName != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
    }
    return UserModel.fromFirebase(user);
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isFirebaseReady) {
      throw Exception('Firebase is not configured. Add google-services.json and uncomment Firebase.initializeApp() in main.dart.');
    }
    final cred = await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return UserModel.fromFirebase(cred.user!);
  }

  Future<void> signOut() async {
    if (_isFirebaseReady) await _auth!.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isFirebaseReady) {
      throw Exception('Firebase is not configured.');
    }
    await _auth!.sendPasswordResetEmail(email: email.trim());
  }
}
