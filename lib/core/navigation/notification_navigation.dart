import '../../features/posts/services/post_service.dart';
import '../constants/app_constants.dart';
import '../models/app_notification.dart';
import '../routes/app_router.dart';

/// Opens the screen associated with a notification tap.
Future<void> navigateFromNotification(
  AppNotification notification, {
  PostService? postService,
}) async {
  switch (notification.type) {
    case AppNotificationType.kycSubmittedAdmin:
      final uid = notification.targetUserId;
      if (uid != null && uid.isNotEmpty) {
        navigatorKey.currentState?.pushNamed(
          AppConstants.routeAdminUserVerification,
          arguments: uid,
        );
      } else {
        navigatorKey.currentState?.pushNamed(AppConstants.routeAdmin);
      }
      return;
    case AppNotificationType.kycApproved:
      navigatorKey.currentState?.pushNamed(AppConstants.routeHome);
      return;
    case AppNotificationType.kycRejected:
      navigatorKey.currentState?.pushNamed(AppConstants.routeVerificationRejected);
      return;
    case AppNotificationType.accountBanned:
      return;
    case AppNotificationType.postFlagged:
      final postId = notification.postId;
      if (postId != null && postService != null) {
        final post = await postService.getPost(postId);
        if (post != null) {
          navigatorKey.currentState?.pushNamed(
            AppConstants.routePostDetail,
            arguments: post,
          );
        }
      }
      return;
    case AppNotificationType.contractBorrowerSigned:
      final contractId = notification.contractId;
      if (contractId != null) {
        navigatorKey.currentState?.pushNamed(
          AppConstants.routeContractQr,
          arguments: contractId,
        );
      }
      return;
    case AppNotificationType.contractCreated:
    case AppNotificationType.contractLenderSigned:
    case AppNotificationType.contractCompleted:
      final contractId = notification.contractId;
      if (contractId != null) {
        navigatorKey.currentState?.pushNamed(
          AppConstants.routeLendBorrowContract,
          arguments: contractId,
        );
      }
      return;
    case AppNotificationType.claimReadyForHandshake:
      final claimId = notification.contractId;
      if (claimId == null) return;
      navigatorKey.currentState?.pushNamed(
        notification.routeName ?? AppConstants.routeLostFoundClaim,
        arguments: claimId,
      );
      return;
    case AppNotificationType.claimCreated:
    case AppNotificationType.claimCompleted:
      final claimId = notification.contractId;
      if (claimId != null) {
        navigatorKey.currentState?.pushNamed(
          AppConstants.routeLostFoundClaim,
          arguments: claimId,
        );
      }
      return;
    case AppNotificationType.contactRequested:
    case AppNotificationType.contactAccepted:
    case AppNotificationType.contactDeclined:
      final requestId = notification.contractId;
      if (requestId != null) {
        navigatorKey.currentState?.pushNamed(
          AppConstants.routeContactRequest,
          arguments: requestId,
        );
      }
      return;
  }
}
