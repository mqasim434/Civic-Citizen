import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of in-app / push notifications.
enum AppNotificationType {
  kycSubmittedAdmin,
  kycApproved,
  kycRejected,
  accountBanned,
  postFlagged,
  contractCreated,
  contractLenderSigned,
  contractBorrowerSigned,
  contractCompleted,
  claimCreated,
  claimReadyForHandshake,
  claimCompleted,
  contactRequested,
  contactAccepted,
  contactDeclined,
}

extension AppNotificationTypeX on AppNotificationType {
  String get value {
    switch (this) {
      case AppNotificationType.kycSubmittedAdmin:
        return 'kyc_submitted_admin';
      case AppNotificationType.kycApproved:
        return 'kyc_approved';
      case AppNotificationType.kycRejected:
        return 'kyc_rejected';
      case AppNotificationType.accountBanned:
        return 'account_banned';
      case AppNotificationType.postFlagged:
        return 'post_flagged';
      case AppNotificationType.contractCreated:
        return 'contract_created';
      case AppNotificationType.contractLenderSigned:
        return 'contract_lender_signed';
      case AppNotificationType.contractBorrowerSigned:
        return 'contract_borrower_signed';
      case AppNotificationType.contractCompleted:
        return 'contract_completed';
      case AppNotificationType.claimCreated:
        return 'claim_created';
      case AppNotificationType.claimReadyForHandshake:
        return 'claim_ready_for_handshake';
      case AppNotificationType.claimCompleted:
        return 'claim_completed';
      case AppNotificationType.contactRequested:
        return 'contact_requested';
      case AppNotificationType.contactAccepted:
        return 'contact_accepted';
      case AppNotificationType.contactDeclined:
        return 'contact_declined';
    }
  }

  static AppNotificationType fromValue(String? v) {
    switch (v) {
      case 'kyc_submitted_admin':
        return AppNotificationType.kycSubmittedAdmin;
      case 'kyc_approved':
        return AppNotificationType.kycApproved;
      case 'kyc_rejected':
        return AppNotificationType.kycRejected;
      case 'account_banned':
        return AppNotificationType.accountBanned;
      case 'post_flagged':
        return AppNotificationType.postFlagged;
      case 'contract_created':
        return AppNotificationType.contractCreated;
      case 'contract_lender_signed':
        return AppNotificationType.contractLenderSigned;
      case 'contract_borrower_signed':
        return AppNotificationType.contractBorrowerSigned;
      case 'contract_completed':
        return AppNotificationType.contractCompleted;
      case 'claim_created':
        return AppNotificationType.claimCreated;
      case 'claim_ready_for_handshake':
        return AppNotificationType.claimReadyForHandshake;
      case 'claim_completed':
        return AppNotificationType.claimCompleted;
      case 'contact_requested':
        return AppNotificationType.contactRequested;
      case 'contact_accepted':
        return AppNotificationType.contactAccepted;
      case 'contact_declined':
        return AppNotificationType.contactDeclined;
      default:
        return AppNotificationType.contractCreated;
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.actorUserId,
    this.actorName,
    this.contractId,
    this.postId,
    this.targetUserId,
    this.routeName,
    this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      type: AppNotificationTypeX.fromValue(d['type'] as String?),
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      read: d['read'] as bool? ?? false,
      actorUserId: d['actorUserId'] as String?,
      actorName: d['actorName'] as String?,
      contractId: d['contractId'] as String?,
      postId: d['postId'] as String?,
      targetUserId: d['targetUserId'] as String?,
      routeName: d['routeName'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final bool read;
  final String? actorUserId;
  final String? actorName;
  final String? contractId;
  final String? postId;
  final String? targetUserId;
  final String? routeName;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
        'type': type.value,
        'title': title,
        'body': body,
        'read': false,
        if (actorUserId != null) 'actorUserId': actorUserId,
        if (actorName != null) 'actorName': actorName,
        if (contractId != null) 'contractId': contractId,
        if (postId != null) 'postId': postId,
        if (targetUserId != null) 'targetUserId': targetUserId,
        if (routeName != null) 'routeName': routeName,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
