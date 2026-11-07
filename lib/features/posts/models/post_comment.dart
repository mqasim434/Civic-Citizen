import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  factory PostComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String postId,
  }) {
    final d = doc.data() ?? {};
    return PostComment(
      id: doc.id,
      postId: postId,
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;
}
