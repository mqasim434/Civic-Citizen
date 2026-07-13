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
  static const String routeVerificationPending = '/verification-pending';
  static const String routeVerificationRejected = '/verification-rejected';
  static const String routeHome = '/home';
  static const String routeAdmin = '/admin';
  static const String routeAdminUserVerification = '/admin-user-verification';
  static const String routePostDetail = '/post-detail';
  static const String routeCreatePost = '/create-post';
  static const String routeEditPost = '/edit-post';
  static const String routeSettings = '/settings';
  static const String routeLendBorrowContract = '/lend-borrow-contract';
  static const String routeContractSignature = '/contract-signature';
  static const String routeContractQr = '/contract-qr';
  static const String routeContractScan = '/contract-scan';
  static const String routeLostFoundClaim = '/lost-found-claim';
  static const String routeClaimQr = '/claim-qr';
  static const String routeClaimScan = '/claim-scan';
  static const String routeNotifications = '/notifications';
  static const String routeEditProfile = '/edit-profile';
  static const String routeAccountBanned = '/account-banned';
  static const String routeBroadcasts = '/broadcasts';
  static const String routeBroadcastDetail = '/broadcast-detail';
  static const String routeContactRequest = '/contact-request';

  // Firestore
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String postsCollection = 'posts';
  static const String contractsCollection = 'lend_borrow_contracts';
  static const String lostFoundClaimsCollection = 'lost_found_claims';
  static const String contactRequestsCollection = 'contact_requests';
  static const String publicTrustCollection = 'public_trust';
  static const String notificationsSubcollection = 'notifications';
  static const String announcementsCollection = 'announcements';
  static const String announcementReadsSubcollection = 'announcement_reads';
  static const String cnicStoragePath = 'kyc/cnic';
  static const String selfieStoragePath = 'kyc/selfie';
  static const String postImagesPath = 'posts';
  static const String announcementImagesPath = 'announcements';
  static const String contractSignaturesPath = 'contracts/signatures';

  /// QR handshake validity after both parties sign.
  static const int contractQrValidityHours = 24;

  // Preferences
  static const String keyThemeMode = 'theme_mode';
}
