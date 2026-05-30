/// Lifecycle of a lend/borrow digital contract.
enum ContractStatus {
  pendingLenderSignature,
  pendingBorrowerSignature,
  readyForHandshake,
  completed,
  cancelled,
}

extension ContractStatusX on ContractStatus {
  String get value {
    switch (this) {
      case ContractStatus.pendingLenderSignature:
        return 'pending_lender_signature';
      case ContractStatus.pendingBorrowerSignature:
        return 'pending_borrower_signature';
      case ContractStatus.readyForHandshake:
        return 'ready_for_handshake';
      case ContractStatus.completed:
        return 'completed';
      case ContractStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ContractStatus.pendingLenderSignature:
        return 'Awaiting lender signature';
      case ContractStatus.pendingBorrowerSignature:
        return 'Awaiting borrower signature';
      case ContractStatus.readyForHandshake:
        return 'Ready for QR handshake';
      case ContractStatus.completed:
        return 'Exchange completed';
      case ContractStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ContractStatus fromValue(String? v) {
    switch (v) {
      case 'pending_borrower_signature':
        return ContractStatus.pendingBorrowerSignature;
      case 'ready_for_handshake':
        return ContractStatus.readyForHandshake;
      case 'completed':
        return ContractStatus.completed;
      case 'cancelled':
        return ContractStatus.cancelled;
      default:
        return ContractStatus.pendingLenderSignature;
    }
  }

  bool get isActive =>
      this != ContractStatus.completed && this != ContractStatus.cancelled;
}
