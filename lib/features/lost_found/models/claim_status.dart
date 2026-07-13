/// Lifecycle of a lost/found recovery claim.
enum ClaimStatus {
  pendingConfirm,
  readyForHandshake,
  completed,
  cancelled,
}

extension ClaimStatusX on ClaimStatus {
  String get value {
    switch (this) {
      case ClaimStatus.pendingConfirm:
        return 'pending_confirm';
      case ClaimStatus.readyForHandshake:
        return 'ready_for_handshake';
      case ClaimStatus.completed:
        return 'completed';
      case ClaimStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ClaimStatus.pendingConfirm:
        return 'Awaiting post author confirmation';
      case ClaimStatus.readyForHandshake:
        return 'Ready for QR confirmation';
      case ClaimStatus.completed:
        return 'Recovery confirmed';
      case ClaimStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ClaimStatus fromValue(String? v) {
    switch (v) {
      case 'ready_for_handshake':
        return ClaimStatus.readyForHandshake;
      case 'completed':
        return ClaimStatus.completed;
      case 'cancelled':
        return ClaimStatus.cancelled;
      default:
        return ClaimStatus.pendingConfirm;
    }
  }

  bool get isActive =>
      this != ClaimStatus.completed && this != ClaimStatus.cancelled;
}
