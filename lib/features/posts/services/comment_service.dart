import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/post_comment.dart';

class CommentService {
  CommentService() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _firestore
          .collection(AppConstants.postsCollection)
          .doc(postId)
          .collection(AppConstants.commentsSubcollection);

  Stream<List<PostComment>> watchComments(String postId) {
    return _comments(postId)
        .orderBy('createdAt', descending: false)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PostComment.fromFirestore(d, postId: postId))
              .toList(),
        );
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw Exception('Comment cannot be empty.');

    final postRef =
        _firestore.collection(AppConstants.postsCollection).doc(postId);
    final commentRef = _comments(postId).doc();

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw Exception('Post not found.');
      final current = (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      tx.set(commentRef, {
        'authorId': authorId,
        'authorName': authorName,
        'text': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(postRef, {
        'commentCount': current + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final postRef =
        _firestore.collection(AppConstants.postsCollection).doc(postId);
    final commentRef = _comments(postId).doc(commentId);

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      final current = (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      tx.delete(commentRef);
      if (postSnap.exists) {
        tx.update(postRef, {
          'commentCount': current > 0 ? current - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
