import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../models/app_notification.dart';

/// Persists in-app notifications and fans out to all admins when needed.
class NotificationService {
  NotificationService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> _userNotifications(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.notificationsSubcollection);

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _userNotifications(userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) =>
            snap.docs.map(AppNotification.fromFirestore).toList());
  }

  Stream<int> watchUnreadCount(String userId) {
    return _userNotifications(userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markRead(String userId, String notificationId) async {
    await _userNotifications(userId).doc(notificationId).update({'read': true});
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _userNotifications(userId).where('read', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> notifyUser({
    required String recipientUserId,
    required AppNotificationType type,
    required String title,
    required String body,
    String? actorUserId,
    String? actorName,
    String? contractId,
    String? postId,
    String? targetUserId,
    String? routeName,
  }) async {
    if (recipientUserId.isEmpty) return;
    if (actorUserId != null && actorUserId == recipientUserId) return;

    try {
      await _userNotifications(recipientUserId).add(
        AppNotification(
          id: '',
          type: type,
          title: title,
          body: body,
          read: false,
          actorUserId: actorUserId,
          actorName: actorName,
          contractId: contractId,
          postId: postId,
          targetUserId: targetUserId,
          routeName: routeName,
        ).toMap(),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('Notification write failed for $recipientUserId: $e');
      // ignore: avoid_print
      print(st);
    }
  }

  Future<void> notifyAdmins({
    required AppNotificationType type,
    required String title,
    required String body,
    String? actorUserId,
    String? actorName,
    String? targetUserId,
    String? routeName,
  }) async {
    QuerySnapshot<Map<String, dynamic>> admins;
    try {
      admins = await _firestore.collection(AppConstants.adminsCollection).get();
    } catch (e, st) {
      // ignore: avoid_print
      print('Could not list admins for notification: $e');
      // ignore: avoid_print
      print(st);
      return;
    }
    for (final doc in admins.docs) {
      await notifyUser(
        recipientUserId: doc.id,
        type: type,
        title: title,
        body: body,
        actorUserId: actorUserId,
        actorName: actorName,
        targetUserId: targetUserId,
        routeName: routeName,
      );
    }
  }

  // --- Lend / borrow ---

  Future<void> notifyContractCreated({
    required String lenderId,
    required String initiatorId,
    required String initiatorName,
    required String contractId,
    required String postId,
    required String itemTitle,
  }) async {
    await notifyUser(
      recipientUserId: lenderId,
      type: AppNotificationType.contractCreated,
      title: 'New lend/borrow agreement',
      body: '$initiatorName started an agreement for "$itemTitle". Sign as lender.',
      actorUserId: initiatorId,
      actorName: initiatorName,
      contractId: contractId,
      postId: postId,
      routeName: AppConstants.routeLendBorrowContract,
    );
  }

  Future<void> notifyContractLenderSigned({
    required String borrowerId,
    required String lenderId,
    required String lenderName,
    required String contractId,
    required String itemTitle,
  }) async {
    await notifyUser(
      recipientUserId: borrowerId,
      type: AppNotificationType.contractLenderSigned,
      title: 'Lender signed',
      body: '$lenderName signed the agreement for "$itemTitle". Please sign as borrower.',
      actorUserId: lenderId,
      actorName: lenderName,
      contractId: contractId,
      routeName: AppConstants.routeLendBorrowContract,
    );
  }

  Future<void> notifyContractBorrowerSigned({
    required String lenderId,
    required String borrowerId,
    required String borrowerName,
    required String contractId,
    required String itemTitle,
  }) async {
    await notifyUser(
      recipientUserId: lenderId,
      type: AppNotificationType.contractBorrowerSigned,
      title: 'Ready for QR handshake',
      body: '$borrowerName signed for "$itemTitle". Show your QR code at meetup.',
      actorUserId: borrowerId,
      actorName: borrowerName,
      contractId: contractId,
      routeName: AppConstants.routeContractQr,
    );
  }

  Future<void> notifyContractCompleted({
    required String lenderId,
    required String borrowerId,
    required String contractId,
    required String itemTitle,
  }) async {
    const title = 'Exchange completed';
    final body = 'Handshake confirmed for "$itemTitle". View agreement & GPS log.';
    await notifyUser(
      recipientUserId: lenderId,
      type: AppNotificationType.contractCompleted,
      title: title,
      body: body,
      contractId: contractId,
      routeName: AppConstants.routeLendBorrowContract,
    );
    await notifyUser(
      recipientUserId: borrowerId,
      type: AppNotificationType.contractCompleted,
      title: title,
      body: body,
      contractId: contractId,
      routeName: AppConstants.routeLendBorrowContract,
    );
  }

  // --- Lost / found recovery ---

  Future<void> notifyClaimCreated({
    required String postAuthorId,
    required String initiatorId,
    required String initiatorName,
    required String claimId,
    required String postId,
    required String itemTitle,
  }) async {
    await notifyUser(
      recipientUserId: postAuthorId,
      type: AppNotificationType.claimCreated,
      title: 'New recovery claim',
      body: '$initiatorName started a recovery claim for "$itemTitle". Confirm when ready to meet.',
      actorUserId: initiatorId,
      actorName: initiatorName,
      contractId: claimId,
      postId: postId,
      routeName: AppConstants.routeLostFoundClaim,
    );
  }

  Future<void> notifyClaimReadyForHandshake({
    required String qrScannerUserId,
    required String qrDisplayUserId,
    required String claimId,
    required String itemTitle,
  }) async {
    await notifyUser(
      recipientUserId: qrScannerUserId,
      type: AppNotificationType.claimReadyForHandshake,
      title: 'Ready for QR confirmation',
      body: 'Recovery claim for "$itemTitle" is confirmed. Scan the QR code at meetup.',
      contractId: claimId,
      routeName: AppConstants.routeClaimScan,
    );
    await notifyUser(
      recipientUserId: qrDisplayUserId,
      type: AppNotificationType.claimReadyForHandshake,
      title: 'Show your QR code',
      body: 'Recovery claim for "$itemTitle" is ready. Show your QR code at meetup.',
      contractId: claimId,
      routeName: AppConstants.routeClaimQr,
    );
  }

  Future<void> notifyClaimCompleted({
    required String ownerId,
    required String finderId,
    required String claimId,
    required String itemTitle,
  }) async {
    const title = 'Recovery confirmed';
    final body = 'QR confirmation logged for "$itemTitle". View recovery record & GPS.';
    await notifyUser(
      recipientUserId: ownerId,
      type: AppNotificationType.claimCompleted,
      title: title,
      body: body,
      contractId: claimId,
      routeName: AppConstants.routeLostFoundClaim,
    );
    await notifyUser(
      recipientUserId: finderId,
      type: AppNotificationType.claimCompleted,
      title: title,
      body: body,
      contractId: claimId,
      routeName: AppConstants.routeLostFoundClaim,
    );
  }

  // --- KYC / admin ---

  Future<void> notifyKycSubmitted({
    required String userId,
    required String displayName,
  }) async {
    await notifyAdmins(
      type: AppNotificationType.kycSubmittedAdmin,
      title: 'New verification request',
      body: '$displayName submitted KYC documents for review.',
      actorUserId: userId,
      actorName: displayName,
      targetUserId: userId,
      routeName: AppConstants.routeAdminUserVerification,
    );
  }

  Future<void> notifyKycApproved({
    required String userId,
    required String displayName,
  }) async {
    await notifyUser(
      recipientUserId: userId,
      type: AppNotificationType.kycApproved,
      title: 'Account verified',
      body: 'Hi $displayName, your identity verification was approved. Welcome to Civic Citizen!',
      routeName: AppConstants.routeHome,
    );
  }

  Future<void> notifyKycRejected({
    required String userId,
    required String displayName,
    String? reason,
  }) async {
    final suffix = reason != null && reason.trim().isNotEmpty
        ? ' Reason: ${reason.trim()}'
        : '';
    await notifyUser(
      recipientUserId: userId,
      type: AppNotificationType.kycRejected,
      title: 'Verification declined',
      body: 'Your verification was not approved.$suffix',
      routeName: AppConstants.routeVerificationRejected,
    );
  }

  Future<void> notifyAccountBanned({
    required String userId,
    String? reason,
  }) async {
    final suffix = reason != null && reason.trim().isNotEmpty
        ? ' Reason: ${reason.trim()}'
        : '';
    await notifyUser(
      recipientUserId: userId,
      type: AppNotificationType.accountBanned,
      title: 'Account restricted',
      body: 'Your account has been banned by an administrator.$suffix',
    );
  }

  Future<void> notifyPostFlagged({
    required String authorId,
    required String postId,
    required String postTitle,
    String? reason,
  }) async {
    final suffix = reason != null && reason.trim().isNotEmpty
        ? ' Reason: ${reason.trim()}'
        : '';
    await notifyUser(
      recipientUserId: authorId,
      type: AppNotificationType.postFlagged,
      title: 'Post flagged',
      body: 'Your post "$postTitle" was marked inappropriate by an admin.$suffix',
      postId: postId,
      routeName: AppConstants.routePostDetail,
    );
  }
}
