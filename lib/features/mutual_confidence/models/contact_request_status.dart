/// Status of a mediated contact request between post author and viewer.
enum ContactRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

extension ContactRequestStatusX on ContactRequestStatus {
  String get value {
    switch (this) {
      case ContactRequestStatus.pending:
        return 'pending';
      case ContactRequestStatus.accepted:
        return 'accepted';
      case ContactRequestStatus.declined:
        return 'declined';
      case ContactRequestStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ContactRequestStatus.pending:
        return 'Pending approval';
      case ContactRequestStatus.accepted:
        return 'Contact shared';
      case ContactRequestStatus.declined:
        return 'Declined';
      case ContactRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == ContactRequestStatus.pending;

  bool get revealsContact => this == ContactRequestStatus.accepted;

  static ContactRequestStatus fromValue(String? v) {
    switch (v) {
      case 'accepted':
        return ContactRequestStatus.accepted;
      case 'declined':
        return ContactRequestStatus.declined;
      case 'cancelled':
        return ContactRequestStatus.cancelled;
      default:
        return ContactRequestStatus.pending;
    }
  }
}
