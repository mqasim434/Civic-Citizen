import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/imagekit_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/imagekit_service.dart';
import '../models/post_model.dart';

/// Handles posts CRUD and image uploads.
class PostService {
  PostService()
      : _firestore = FirebaseFirestore.instance,
        _imagekit = ImageKitService(ImageKitConfig.instance),
        _picker = ImagePicker();

  final FirebaseFirestore _firestore;
  final ImageKitService _imagekit;
  final ImagePicker _picker;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(AppConstants.postsCollection);

  /// Stream publicly listed posts (excludes fulfilled / flagged).
  /// Module filtering is client-side so legacy values like `lost_found` still match.
  Stream<List<PostModel>> watchPosts({PostModule? module}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      var posts = snap.docs
          .map(PostModel.fromFirestore)
          .where((p) => p.isPubliclyListed && !p.isInappropriate)
          .toList();
      if (module != null) {
        posts = posts
            .where((p) => p.module == module && !p.isStandaloneAd)
            .toList();
      }
      return posts;
    });
  }

  /// All posts by author (active + fulfilled).
  Stream<List<PostModel>> watchPostsByAuthor(String authorId) {
    return _posts
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PostModel.fromFirestore(d)).toList());
  }

  /// Active listings only — for profile "My posts".
  Stream<List<PostModel>> watchActivePostsByAuthor(String authorId) {
    return watchPostsByAuthor(authorId).map(
      (posts) => posts.where((p) => p.isPubliclyListed).toList(),
    );
  }

  Stream<PostModel?> watchPost(String id) {
    return _posts.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PostModel.fromFirestore(doc);
    });
  }

  /// Get single post by id.
  Future<PostModel?> getPost(String id) async {
    final doc = await _posts.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return PostModel.fromFirestore(doc);
  }

  /// Upload post image and return URL.
  Future<String> uploadPostImage(String postId, File image) async {
    return _imagekit.upload(
      file: image,
      folder: '${AppConstants.postImagesPath}/$postId',
    );
  }

  /// Create a new post.
  Future<String> createPost(PostModel post) async {
    final docRef = await _posts.add(post.toMap());
    return docRef.id;
  }

  /// Update post.
  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _posts.doc(id).update(data);
  }

  Stream<bool> watchLiked({required String postId, required String uid}) {
    return _posts
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleLike({required String postId, required String uid}) async {
    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);
    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw Exception('Post not found.');
      final likeSnap = await tx.get(likeRef);
      final current = (postSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {
          'likeCount': current > 0 ? current - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {
          'likeCount': current + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Counts one unique viewer. Safe to call more than once for the same user.
  Future<void> recordUniqueView({
    required String postId,
    required String uid,
  }) async {
    final postRef = _posts.doc(postId);
    final viewRef = postRef.collection('views').doc(uid);
    await _firestore.runTransaction((tx) async {
      final viewSnap = await tx.get(viewRef);
      if (viewSnap.exists) return;
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;
      final current = (postSnap.data()?['viewCount'] as num?)?.toInt() ?? 0;
      tx.set(viewRef, {'createdAt': FieldValue.serverTimestamp()});
      tx.update(postRef, {
        'viewCount': current + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Delete post.
  Future<void> deletePost(String id) async {
    await _posts.doc(id).delete();
  }

  /// Pick image from gallery or camera.
  Future<File?> pickImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }
}
