import 'package:cloud_firestore/cloud_firestore.dart';

import '../../posts/models/post_model.dart';
import 'contact_request_status.dart';

/// Mediated contact request — phone revealed only after author accepts.
class ContactRequest {
  const ContactRequest({
    required this.id,
    required this.postId,
    required this.postModule,
    required this.itemTitle,
    required this.requesterId,
    required this.requesterName,
    required this.authorId,
    required this.authorName,
    required this.status,
    this.revealedContactNumber,
    this.suggestedMeetupLabel,
    this.meetupLatitude,
    this.meetupLongitude,
    this.createdAt,
    this.updatedAt,
    this.respondedAt,
    this.contactRevealedAt,
  });

  factory ContactRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return ContactRequest(
      id: doc.id,
      postId: d['postId'] as String? ?? '',
      postModule: PostModuleX.fromValue(d['postModule'] as String?),
      itemTitle: d['itemTitle'] as String? ?? '',
      requesterId: d['requesterId'] as String? ?? '',
      requesterName: d['requesterName'] as String? ?? '',
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      status: ContactRequestStatusX.fromValue(d['status'] as String?),
      revealedContactNumber: d['revealedContactNumber'] as String?,
      suggestedMeetupLabel: d['suggestedMeetupLabel'] as String?,
      meetupLatitude: (d['meetupLatitude'] as num?)?.toDouble(),
      meetupLongitude: (d['meetupLongitude'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      respondedAt: (d['respondedAt'] as Timestamp?)?.toDate(),
      contactRevealedAt: (d['contactRevealedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String postId;
  final PostModule postModule;
  final String itemTitle;
  final String requesterId;
  final String requesterName;
  final String authorId;
  final String authorName;
  final ContactRequestStatus status;
  final String? revealedContactNumber;
  final String? suggestedMeetupLabel;
  final double? meetupLatitude;
  final double? meetupLongitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? respondedAt;
  final DateTime? contactRevealedAt;

  bool involvesUser(String uid) => requesterId == uid || authorId == uid;

  String otherPartyId(String uid) =>
      uid == authorId ? requesterId : authorId;

  String otherPartyName(String uid) =>
      uid == authorId ? requesterName : authorName;
}
