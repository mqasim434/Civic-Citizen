import 'package:cloud_firestore/cloud_firestore.dart';

/// [paused] and [stopped] are set by the advertiser; [removed] by an admin.
enum AdStatus { active, paused, expired, stopped, removed }

extension AdStatusX on AdStatus {
  String get value {
    switch (this) {
      case AdStatus.active:
        return 'active';
      case AdStatus.paused:
        return 'paused';
      case AdStatus.stopped:
        return 'stopped';
      case AdStatus.expired:
        return 'expired';
      case AdStatus.removed:
        return 'removed';
    }
  }

  static AdStatus fromValue(String? v) {
    switch (v) {
      case 'paused':
        return AdStatus.paused;
      case 'stopped':
        return AdStatus.stopped;
      case 'expired':
        return AdStatus.expired;
      case 'removed':
        return AdStatus.removed;
      default:
        return AdStatus.active;
    }
  }
}

class AdModel {
  const AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.status,
    required this.pointsSpent,
    this.imageUrl,
    this.contactNumber,
    this.city,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.postId,
  });

  factory AdModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AdModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      status: AdStatusX.fromValue(d['status'] as String?),
      pointsSpent: (d['pointsSpent'] as num?)?.toInt() ?? 0,
      imageUrl: d['imageUrl'] as String?,
      contactNumber: d['contactNumber'] as String?,
      city: d['city'] as String?,
      startsAt: (d['startsAt'] as Timestamp?)?.toDate(),
      endsAt: (d['endsAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      postId: d['postId'] as String?,
    );
  }

  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final AdStatus status;
  final int pointsSpent;
  final String? imageUrl;
  final String? contactNumber;
  final String? city;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final String? postId;

  bool get isLive {
    if (status != AdStatus.active) return false;
    final end = endsAt;
    if (end == null) return true;
    return end.isAfter(DateTime.now());
  }
}
