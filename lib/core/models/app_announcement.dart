import 'package:cloud_firestore/cloud_firestore.dart';

class AppAnnouncement {
  const AppAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.active,
    this.imageUrl,
    this.createdBy,
    this.createdAt,
  });

  factory AppAnnouncement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AppAnnouncement(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      active: d['active'] as bool? ?? false,
      imageUrl: d['imageUrl'] as String?,
      createdBy: d['createdBy'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String title;
  final String body;
  final bool active;
  final String? imageUrl;
  final String? createdBy;
  final DateTime? createdAt;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  Map<String, dynamic> toCreateMap({
    required String adminUid,
    String? imageUrl,
  }) =>
      {
        'title': title,
        'body': body,
        'active': true,
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
      };
}
