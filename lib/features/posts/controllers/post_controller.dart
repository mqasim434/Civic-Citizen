import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';

/// Posts state and actions.
class PostController extends ChangeNotifier {
  PostController(this._postService);

  final PostService _postService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Stream<List<PostModel>> watchPosts({PostModule? module}) =>
      _postService.watchPosts(module: module);

  Stream<List<PostModel>> watchMyPosts(String authorId) =>
      _postService.watchPostsByAuthor(authorId);

  Future<PostModel?> getPost(String id) => _postService.getPost(id);

  Future<String?> createPost({
    required PostModule module,
    required String title,
    required String description,
    required String authorId,
    required String authorName,
    required String contactNumber,
    String? category,
    String? categoryCustom,
    required String location,
    List<File>? images,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final post = PostModel(
        id: '',
        module: module,
        title: title,
        description: description,
        authorId: authorId,
        authorName: authorName,
        contactNumber: contactNumber,
        category: category,
        categoryCustom: categoryCustom,
        location: location,
      );
      final id = await _postService.createPost(post);
      if (images != null && images.isNotEmpty && id.isNotEmpty) {
        final urls = <String>[];
        for (final img in images) {
          final url = await _postService.uploadPostImage(id, img);
          urls.add(url);
        }
        await _postService.updatePost(id, {'imageUrls': urls});
      }
      _setLoading(false);
      return id;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  Future<File?> pickImage() => _postService.pickImage();

  Future<bool> updatePost({
    required String id,
    required PostModule module,
    required String title,
    required String description,
    required String contactNumber,
    String? category,
    String? categoryCustom,
    required String location,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final data = <String, dynamic>{
        'module': module.value,
        'title': title,
        'description': description,
        'contactNumber': contactNumber,
        'category': category,
        'location': location,
      };
      if (categoryCustom != null && categoryCustom.isNotEmpty) {
        data['categoryCustom'] = categoryCustom;
      } else {
        data['categoryCustom'] = FieldValue.delete();
      }
      await _postService.updatePost(id, data);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String id) async {
    _setLoading(true);
    _error = null;
    try {
      await _postService.deletePost(id);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
