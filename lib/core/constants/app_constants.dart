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
  static const String routeHome = '/home';
}
