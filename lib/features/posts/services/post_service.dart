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

  /// Stream publicly listed posts (excludes fulfilled lend/borrow listings).
  Stream<List<PostModel>> watchPosts({PostModule? module}) {
    final Query<Map<String, dynamic>> q = module != null
        ? _posts
            .where('module', isEqualTo: module.value)
            .orderBy('createdAt', descending: true)
        : _posts.orderBy('createdAt', descending: true);
    return q.snapshots().map((snap) => snap.docs
        .map((d) => PostModel.fromFirestore(d))
        .where((p) => p.isPubliclyListed && !p.isInappropriate)
        .toList());
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
