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
  static const String routeHelpSupport = '/help-support';
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
  static const String routeRewards = '/rewards';
  static const String routeCreateAd = '/create-ad';
  static const String routeEvents = '/events';
  static const String routeFavourites = '/favourites';
  static const String routeEventDetail = '/event-detail';

  // Firestore
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String postsCollection = 'posts';
  static const String contractsCollection = 'lend_borrow_contracts';
  static const String lostFoundClaimsCollection = 'lost_found_claims';
  static const String contactRequestsCollection = 'contact_requests';
  static const String publicTrustCollection = 'public_trust';
  static const String userIndexCollection = 'user_index';
  static const String postAlertsCollection = 'post_alerts';
  static const String eventAlertsCollection = 'event_alerts';
  static const String pointLedgerCollection = 'point_ledger';
  static const String adsCollection = 'ads';
  static const String eventsCollection = 'events';
  static const String commentsSubcollection = 'comments';
  static const String notificationsSubcollection = 'notifications';
  static const String favouritesSubcollection = 'favourites';
  static const String announcementsCollection = 'announcements';
  static const String announcementReadsSubcollection = 'announcement_reads';
  static const String cnicStoragePath = 'kyc/cnic';
  static const String selfieStoragePath = 'kyc/selfie';
  static const String postImagesPath = 'posts';
  static const String profileImagesPath = 'profiles';
  static const String announcementImagesPath = 'announcements';
  static const String adImagesPath = 'ads';
  static const String eventDocsPath = 'events';
  static const String contractSignaturesPath = 'contracts/signatures';

  /// Points economy
  /// Default min ad rate; live value lives in Firestore `app_config/ads`.
  static const int defaultAdPointsCost = 20;
  static const int adDurationDays = 3;
  static const String appConfigCollection = 'app_config';
  static const String adsConfigDoc = 'ads';
  static const int funFlipsPerDay = 3;
  /// App-scheme deep link (used by hosting redirect / App Links).
  static const String sharePostScheme = 'civiccitizen';
  static const String sharePostHost = 'post';
  static String sharePostAppUrl(String postId) =>
      '$sharePostScheme://$sharePostHost/$postId';

  /// HTTPS share link — clickable in WhatsApp; hosted on Firebase Hosting.
  static const String sharePostHttpsHost = 'civic-citizen-3d0af.web.app';
  static String sharePostUrl(String postId) =>
      'https://$sharePostHttpsHost/post/$postId';

  /// QR handshake validity after both parties sign.
  static const int contractQrValidityHours = 24;

  // Preferences
  static const String keyThemeMode = 'theme_mode';
}
