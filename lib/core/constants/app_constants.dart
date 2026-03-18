/// Application-wide constants for Civic Citizen.
class AppConstants {
  AppConstants._();

  static const String appName = 'Civic Citizen';
  static const String appTagline = 'Connect. Share. Trust.';

  // Auth
  static const int splashDurationSeconds = 2;
  static const int minPasswordLength = 6;

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeKyc = '/kyc';
  static const String routeHome = '/home';
  static const String routePostDetail = '/post-detail';
  static const String routeCreatePost = '/create-post';
  static const String routeEditPost = '/edit-post';
  static const String routeSettings = '/settings';

  // Firestore
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String cnicStoragePath = 'kyc/cnic';
  static const String selfieStoragePath = 'kyc/selfie';
  static const String postImagesPath = 'posts';

  // Preferences
  static const String keyThemeMode = 'theme_mode';
}
