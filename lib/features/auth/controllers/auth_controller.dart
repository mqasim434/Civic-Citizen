import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state and actions — used with Provider.
class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
    _user = _authService.currentUser;
  }

  final AuthService _authService;

  UserModel? _user;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _passwordResetLoading = false;
  bool get isPasswordResetLoading => _passwordResetLoading;

  String? _error;
  String? get error => _error;
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Returns the created user on success, null on failure.
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _setLoading(false);
      return user;
    } on FirebaseAuthException catch (e) {
      _error = _messageFromCode(e.code);
      _setLoading(false);
      return null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.signInWithEmail(email: email, password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _messageFromCode(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.signOut();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _passwordResetLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      _error = _messageFromCode(e.code);
    } catch (e) {
      _error = e.toString();
    } finally {
      _passwordResetLoading = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  static String _messageFromCode(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
