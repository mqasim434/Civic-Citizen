/// KYC verification status for a user.
enum KycStatus {
  pending,
  verified,
  rejected,
}

extension KycStatusX on KycStatus {
  String get label {
    switch (this) {
      case KycStatus.pending:
        return 'Pending verification';
      case KycStatus.verified:
        return 'Verified';
      case KycStatus.rejected:
        return 'Rejected';
    }
  }
}
