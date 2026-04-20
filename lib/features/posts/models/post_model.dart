import 'package:cloud_firestore/cloud_firestore.dart';

/// Civic post module types.
enum PostModule {
  lost,
  found,
  charity,
  resources,
  lend,
  borrow,
}

extension PostModuleX on PostModule {
  String get value {
    switch (this) {
      case PostModule.lost:
        return 'lost';
      case PostModule.found:
        return 'found';
      case PostModule.charity:
        return 'charity';
      case PostModule.resources:
        return 'resources';
      case PostModule.lend:
        return 'lend';
      case PostModule.borrow:
        return 'borrow';
    }
  }

  String get label {
    switch (this) {
      case PostModule.lost:
        return 'Lost';
      case PostModule.found:
        return 'Found';
      case PostModule.charity:
        return 'Charity';
      case PostModule.resources:
        return 'Resources';
      case PostModule.lend:
        return 'Lend';
      case PostModule.borrow:
        return 'Borrow';
    }
  }

  static PostModule fromValue(String? v) {
    switch (v) {
      case 'found':
        return PostModule.found;
      case 'charity':
        return PostModule.charity;
      case 'resources':
        return PostModule.resources;
      case 'lend':
        return PostModule.lend;
      case 'borrow':
        return PostModule.borrow;
      case 'lost_found':
        return PostModule.lost;
      case 'lend_borrow':
        return PostModule.lend;
      default:
        return PostModule.lost;
    }
  }
}

/// Post model for Civic Citizen.
class PostModel {
  const PostModel({
    required this.id,
    required this.module,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.contactNumber,
    this.category,
    this.categoryCustom,
    this.location,
    this.imageUrls = const [],
    this.isInappropriate = false,
    this.inappropriateReason,
    this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return PostModel(
      id: doc.id,
      module: PostModuleX.fromValue(d['module'] as String?),
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      contactNumber: d['contactNumber'] as String? ?? '',
      category: d['category'] as String?,
      categoryCustom: d['categoryCustom'] as String?,
      location: d['location'] as String?,
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? []),
      isInappropriate: d['isInappropriate'] as bool? ?? false,
      inappropriateReason: d['inappropriateReason'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final PostModule module;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String contactNumber;
  final String? category;
  /// When [category] is "Other", user-defined label (still grouped under Other).
  final String? categoryCustom;
  final String? location;
  final List<String> imageUrls;
  final bool isInappropriate;
  final String? inappropriateReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Category line for UI: "Other: …" when custom, else [category].
  String? get categoryDisplayLabel {
    if (category == null) return null;
    if (category == 'Other' &&
        categoryCustom != null &&
        categoryCustom!.trim().isNotEmpty) {
      return 'Other: ${categoryCustom!.trim()}';
    }
    return category;
  }

  Map<String, dynamic> toMap() => {
        'module': module.value,
        'title': title,
        'description': description,
        'authorId': authorId,
        'authorName': authorName,
        'contactNumber': contactNumber,
        'category': category,
        if (categoryCustom != null) 'categoryCustom': categoryCustom,
        'location': location,
        'imageUrls': imageUrls,
        'isInappropriate': isInappropriate,
        if (inappropriateReason != null) 'inappropriateReason': inappropriateReason,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
