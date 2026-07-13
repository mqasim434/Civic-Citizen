import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../posts/models/post_model.dart';
import '../models/contact_request.dart';
import '../models/contact_request_status.dart';

/// Mediated contact requests — phone revealed only after author approval.
class ContactRequestService {
  ContactRequestService({NotificationService? notifications})
      : _firestore = FirebaseFirestore.instance,
        _notifications = notifications;

  final FirebaseFirestore _firestore;
  final NotificationService? _notifications;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.contactRequestsCollection);

  Stream<ContactRequest?> watchRequest(String requestId) {
    return _requests.doc(requestId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ContactRequest.fromFirestore(doc);
    });
  }

  Stream<ContactRequest?> watchActiveRequestForPost({
    required String postId,
    required String userId,
  }) {
    return _requests
        .where('postId', isEqualTo: postId)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      ContactRequest? latest;
      for (final doc in snap.docs) {
        final request = ContactRequest.fromFirestore(doc);
        if (!request.status.isActive && !request.status.revealsContact) {
          continue;
        }
        if (latest == null ||
            (request.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .isAfter(
              latest.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            )) {
          latest = request;
        }
      }
      return latest;
    });
  }

  Future<ContactRequest?> getRequest(String requestId) async {
    final doc = await _requests.doc(requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ContactRequest.fromFirestore(doc);
  }

  Future<String> createRequest({
    required PostModel post,
    required String requesterId,
    required String requesterName,
  }) async {
    if (post.authorId == requesterId) {
      throw Exception('You cannot request contact on your own post.');
    }
    if (post.isFulfilled) {
      throw Exception('This listing is no longer available.');
    }

    final existing = await _requests
        .where('postId', isEqualTo: post.id)
        .where('participantIds', arrayContains: requesterId)
        .get();
    for (final doc in existing.docs) {
      final request = ContactRequest.fromFirestore(doc);
      if (request.status.isActive || request.status.revealsContact) {
        throw Exception('You already have an active contact request for this post.');
      }
    }

    final docRef = await _requests.add({
      'postId': post.id,
      'postModule': post.module.value,
      'itemTitle': post.title,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'authorId': post.authorId,
      'authorName': post.authorName,
      'participantIds': [requesterId, post.authorId],
      'status': ContactRequestStatus.pending.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifications?.notifyContactRequested(
      authorId: post.authorId,
      requesterId: requesterId,
      requesterName: requesterName,
      requestId: docRef.id,
      postId: post.id,
      itemTitle: post.title,
    );
    return docRef.id;
  }

  Future<void> acceptRequest({
    required String requestId,
    required String authorId,
  }) async {
    final request = await _requireRequest(requestId);
    if (request.authorId != authorId) {
      throw Exception('Only the post author can accept this request.');
    }
    if (request.status != ContactRequestStatus.pending) {
      throw Exception('This request is no longer pending.');
    }

    final postSnap = await _firestore
        .collection(AppConstants.postsCollection)
        .doc(request.postId)
        .get();
    final contactNumber = postSnap.data()?['contactNumber'] as String? ?? '';

    await _requests.doc(requestId).update({
      'status': ContactRequestStatus.accepted.value,
      'revealedContactNumber': contactNumber,
      'contactRevealedAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifications?.notifyContactAccepted(
      requesterId: request.requesterId,
      authorId: authorId,
      authorName: request.authorName,
      requestId: requestId,
      itemTitle: request.itemTitle,
    );
  }

  Future<void> declineRequest({
    required String requestId,
    required String authorId,
  }) async {
    final request = await _requireRequest(requestId);
    if (request.authorId != authorId) {
      throw Exception('Only the post author can decline this request.');
    }
    if (request.status != ContactRequestStatus.pending) {
      throw Exception('This request is no longer pending.');
    }

    await _requests.doc(requestId).update({
      'status': ContactRequestStatus.declined.value,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notifications?.notifyContactDeclined(
      requesterId: request.requesterId,
      authorId: authorId,
      authorName: request.authorName,
      requestId: requestId,
      itemTitle: request.itemTitle,
    );
  }

  Future<void> cancelRequest({
    required String requestId,
    required String requesterId,
  }) async {
    final request = await _requireRequest(requestId);
    if (request.requesterId != requesterId) {
      throw Exception('Only the requester can cancel this request.');
    }
    if (request.status != ContactRequestStatus.pending) {
      throw Exception('This request can no longer be cancelled.');
    }

    await _requests.doc(requestId).update({
      'status': ContactRequestStatus.cancelled.value,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveMeetupSuggestion({
    required String requestId,
    required String userId,
    required String label,
    double? latitude,
    double? longitude,
  }) async {
    final request = await _requireRequest(requestId);
    if (!request.involvesUser(userId)) {
      throw Exception('You are not a party to this contact request.');
    }
    if (!request.status.revealsContact) {
      throw Exception('Meetup suggestions are available after contact is shared.');
    }

    await _requests.doc(requestId).update({
      'suggestedMeetupLabel': label.trim(),
      if (latitude != null) 'meetupLatitude': latitude,
      if (longitude != null) 'meetupLongitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<ContactRequest> _requireRequest(String requestId) async {
    final request = await getRequest(requestId);
    if (request == null) throw Exception('Contact request not found.');
    return request;
  }
}
