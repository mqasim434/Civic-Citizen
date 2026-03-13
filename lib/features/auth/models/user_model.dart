import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Represents the authenticated user in Civic Citizen.
class UserModel {
  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
  });

  factory UserModel.fromFirebase(firebase_auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
}
