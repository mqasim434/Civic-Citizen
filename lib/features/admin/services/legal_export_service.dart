import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../lend_borrow/models/contract_status.dart';
import '../../lend_borrow/models/lend_borrow_contract.dart';
import '../../lost_found/models/claim_status.dart';
import '../../lost_found/models/lost_found_claim.dart';
import '../../posts/models/post_model.dart';

/// Builds a text evidence package for admin legal / dispute review.
class LegalExportService {
  LegalExportService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String> buildEvidencePackage(String userId) async {
    if (userId.isEmpty) throw Exception('User ID is required.');

    final userSnap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    if (!userSnap.exists) {
      throw Exception('User profile not found.');
    }
    final profile = userSnap.data();
    if (profile == null) {
      throw Exception('User profile not found.');
    }

    final contractsSnap = await _firestore
        .collection(AppConstants.contractsCollection)
        .where('participantIds', arrayContains: userId)
        .get();

    final claimsSnap = await _firestore
        .collection(AppConstants.lostFoundClaimsCollection)
        .where('participantIds', arrayContains: userId)
        .get();

    final postsSnap = await _firestore
        .collection(AppConstants.postsCollection)
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .get();

    final buffer = StringBuffer()
      ..writeln('CIVIC CITIZEN — LEGAL EVIDENCE EXPORT')
      ..writeln('Generated (UTC): ${DateTime.now().toUtc().toIso8601String()}')
      ..writeln('Exported for user ID: $userId')
      ..writeln('')
      ..writeln(_section('Account'))
      ..writeln('Display name: ${profile['displayName'] ?? '—'}')
      ..writeln('Email: ${profile['email'] ?? '—'}')
      ..writeln('Verification status: ${profile['verificationStatus'] ?? '—'}')
      ..writeln('Banned: ${profile['isBanned'] == true ? 'yes' : 'no'}')
      ..writeln('Ban reason: ${profile['banReason'] ?? '—'}')
      ..writeln('Verified at: ${_ts(profile['verifiedAt'])}')
      ..writeln('Rejected at: ${_ts(profile['rejectedAt'])}')
      ..writeln('Rejection reason: ${profile['rejectionReason'] ?? '—'}')
      ..writeln('')
      ..writeln(_section('KYC documents (ImageKit URLs)'))
      ..writeln('CNIC front: ${profile['cnicFrontImageUrl'] ?? profile['cnicImageUrl'] ?? '—'}')
      ..writeln('CNIC back: ${profile['cnicBackImageUrl'] ?? '—'}')
      ..writeln('Selfie: ${profile['selfieImageUrl'] ?? '—'}')
      ..writeln('KYC submitted: ${_ts(profile['kycSubmittedAt'])}')
      ..writeln('')
      ..writeln(_section('Lend / borrow contracts (${contractsSnap.docs.length})'));

    if (contractsSnap.docs.isEmpty) {
      buffer.writeln('None.');
    } else {
      for (final doc in contractsSnap.docs) {
        buffer.writeln(_formatContract(LendBorrowContract.fromFirestore(doc)));
      }
    }

    buffer
      ..writeln('')
      ..writeln(_section('Lost / found recoveries (${claimsSnap.docs.length})'));

    if (claimsSnap.docs.isEmpty) {
      buffer.writeln('None.');
    } else {
      for (final doc in claimsSnap.docs) {
        buffer.writeln(_formatClaim(LostFoundClaim.fromFirestore(doc)));
      }
    }

    buffer
      ..writeln('')
      ..writeln(_section('Recent posts by user (${postsSnap.docs.length} shown, max 25)'));

    if (postsSnap.docs.isEmpty) {
      buffer.writeln('None.');
    } else {
      for (final doc in postsSnap.docs) {
        final d = doc.data();
        buffer.writeln(
          '- [${d['module'] ?? '?'}] ${d['title'] ?? 'Untitled'} (id: ${doc.id}, '
          'status: ${d['listingStatus'] ?? 'active'})',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln(_section('Notes'))
      ..writeln(
        'Image and signature files are hosted on ImageKit at the URLs above. '
        'GPS coordinates reflect in-app QR handshake logs stored in Firestore. '
        'This export is for authorized admin review only.',
      );

    return buffer.toString();
  }

  String _section(String title) => '=== $title ===';

  String _ts(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
    return '—';
  }

  String _formatContract(LendBorrowContract c) {
    final buf = StringBuffer()
      ..writeln('')
      ..writeln('Contract ID: ${c.id}')
      ..writeln('Post ID: ${c.postId}')
      ..writeln('Item: ${c.itemTitle}')
      ..writeln('Status: ${c.status.value}')
      ..writeln('Lender: ${c.lenderName} (${c.lenderId})')
      ..writeln('Borrower: ${c.borrowerName} (${c.borrowerId})')
      ..writeln('Created: ${_dt(c.createdAt)}')
      ..writeln('Completed: ${_dt(c.completedAt ?? c.handshakeAt)}')
      ..writeln('Lender signature URL: ${c.lenderSignatureUrl ?? '—'}')
      ..writeln('Borrower signature URL: ${c.borrowerSignatureUrl ?? '—'}')
      ..writeln('Handshake GPS: ${_gps(c.handshakeLatitude, c.handshakeLongitude)}')
      ..writeln('Handshake address: ${c.handshakeAddress ?? '—'}')
      ..writeln('Handshake at: ${_dt(c.handshakeAt)}')
      ..writeln('Scanned by user: ${c.handshakeScannedByUserId ?? '—'}')
      ..writeln('Terms excerpt: ${_excerpt(c.termsText)}');
    return buf.toString();
  }

  String _formatClaim(LostFoundClaim c) {
    final buf = StringBuffer()
      ..writeln('')
      ..writeln('Claim ID: ${c.id}')
      ..writeln('Post ID: ${c.postId}')
      ..writeln('Module: ${c.postModule.value}')
      ..writeln('Item: ${c.itemTitle}')
      ..writeln('Status: ${c.status.value}')
      ..writeln('Owner: ${c.ownerName} (${c.ownerId})')
      ..writeln('Finder: ${c.finderName} (${c.finderId})')
      ..writeln('Created: ${_dt(c.createdAt)}')
      ..writeln('Completed: ${_dt(c.completedAt ?? c.handshakeAt)}')
      ..writeln('Handshake GPS: ${_gps(c.handshakeLatitude, c.handshakeLongitude)}')
      ..writeln('Handshake address: ${c.handshakeAddress ?? '—'}')
      ..writeln('Handshake at: ${_dt(c.handshakeAt)}')
      ..writeln('Scanned by user: ${c.handshakeScannedByUserId ?? '—'}')
      ..writeln('Summary excerpt: ${_excerpt(c.summaryText ?? c.itemDescription)}');
    return buf.toString();
  }

  String _dt(DateTime? dt) =>
      dt == null ? '—' : dt.toUtc().toIso8601String();

  String _gps(double? lat, double? lng) {
    if (lat == null || lng == null) return '—';
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  String _excerpt(String? text, {int maxLen = 280}) {
    if (text == null || text.trim().isEmpty) return '—';
    final t = text.trim().replaceAll('\n', ' ');
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}…';
  }
}
