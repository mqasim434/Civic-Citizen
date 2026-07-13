import 'package:cloud_firestore/cloud_firestore.dart';

import 'announcement_poll.dart';

class AppAnnouncement {
  const AppAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.active,
    this.imageUrl,
    this.pollQuestion,
    this.pollOptions = const [],
    this.createdBy,
    this.createdAt,
  });

  factory AppAnnouncement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final rawOptions = d['pollOptions'] as List<dynamic>? ?? [];
    return AppAnnouncement(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      active: d['active'] as bool? ?? false,
      imageUrl: d['imageUrl'] as String?,
      pollQuestion: d['pollQuestion'] as String?,
      pollOptions: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(AnnouncementPollOption.fromMap)
          .where((o) => o.id.isNotEmpty && o.text.isNotEmpty)
          .toList(),
      createdBy: d['createdBy'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String title;
  final String body;
  final bool active;
  final String? imageUrl;
  final String? pollQuestion;
  final List<AnnouncementPollOption> pollOptions;
  final String? createdBy;
  final DateTime? createdAt;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get hasPoll =>
      pollQuestion != null &&
      pollQuestion!.trim().isNotEmpty &&
      pollOptions.length >= 2;

  Map<String, dynamic> toCreateMap({
    required String adminUid,
    String? imageUrl,
    String? pollQuestion,
    List<AnnouncementPollOption>? pollOptions,
  }) =>
      {
        'title': title,
        'body': body,
        'active': true,
        'createdBy': adminUid,
        'createdAt': FieldValue.serverTimestamp(),
        if (imageUrl != null && imageUrl.trim().isNotEmpty)
          'imageUrl': imageUrl.trim(),
        if (pollQuestion != null &&
            pollQuestion.trim().isNotEmpty &&
            pollOptions != null &&
            pollOptions.length >= 2) ...{
          'pollQuestion': pollQuestion.trim(),
          'pollOptions': pollOptions.map((o) => o.toMap()).toList(),
        },
      };
}
