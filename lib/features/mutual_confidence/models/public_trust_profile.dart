import 'package:cloud_firestore/cloud_firestore.dart';

/// Public trust summary readable by any signed-in user.
class PublicTrustProfile {
  const PublicTrustProfile({
    required this.userId,
    required this.displayName,
    this.verificationStatus = 'pending',
    this.completedExchanges = 0,
    this.completedRecoveries = 0,
    this.memberSince,
    this.updatedAt,
  });

  factory PublicTrustProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return PublicTrustProfile(
      userId: doc.id,
      displayName: d['displayName'] as String? ?? 'Community member',
      verificationStatus: d['verificationStatus'] as String? ?? 'pending',
      completedExchanges: d['completedExchanges'] as int? ?? 0,
      completedRecoveries: d['completedRecoveries'] as int? ?? 0,
      memberSince: (d['memberSince'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String userId;
  final String displayName;
  final String verificationStatus;
  final int completedExchanges;
  final int completedRecoveries;
  final DateTime? memberSince;
  final DateTime? updatedAt;

  bool get isVerified => verificationStatus == 'verified';

  int get totalCompletedHandshakes =>
      completedExchanges + completedRecoveries;
}
