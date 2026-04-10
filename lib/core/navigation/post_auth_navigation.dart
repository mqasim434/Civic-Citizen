import '../constants/app_constants.dart';
import '../routes/app_router.dart';
import '../../features/kyc/models/kyc_status.dart';
import '../../features/kyc/services/kyc_service.dart';
import '../../features/admin/services/admin_service.dart';

/// Where to send the user after splash or successful login.
enum PostAuthDestination {
  kyc,
  verificationPending,
  verificationRejected,
  home,
  admin,
}

/// Resolves navigation from auth + Firestore profile + admin flag.
Future<PostAuthDestination> resolvePostAuthDestination({
  required String uid,
  required KycService kycService,
  required AdminService adminService,
}) async {
  if (await adminService.isAdmin(uid)) {
    return PostAuthDestination.admin;
  }
  final profile = await kycService.getUserProfile(uid);
  if (!KycService.hasSubmittedKyc(profile)) {
    return PostAuthDestination.kyc;
  }
  final status = profile?['verificationStatus'] as String?;
  if (status == KycStatus.verified.name) {
    return PostAuthDestination.home;
  }
  if (status == KycStatus.rejected.name) {
    return PostAuthDestination.verificationRejected;
  }
  return PostAuthDestination.verificationPending;
}

/// Pushes replacement route for [destination]. [kycArgs] required for kyc.
void pushDestination(
  PostAuthDestination destination, {
  required String uid,
  String displayName = '',
  String email = '',
}) {
  switch (destination) {
    case PostAuthDestination.kyc:
      navigatorKey.currentState?.pushReplacementNamed(
        AppConstants.routeKyc,
        arguments: {
          'uid': uid,
          'displayName': displayName,
          'email': email,
        },
      );
      break;
    case PostAuthDestination.verificationPending:
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeVerificationPending);
      break;
    case PostAuthDestination.verificationRejected:
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeVerificationRejected);
      break;
    case PostAuthDestination.home:
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeHome);
      break;
    case PostAuthDestination.admin:
      navigatorKey.currentState?.pushReplacementNamed(AppConstants.routeAdmin);
      break;
  }
}
