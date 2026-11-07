import 'package:cloud_firestore/cloud_firestore.dart';

import 'post_listing_status.dart';

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
    this.itemCondition,
    this.listingStatus = PostListingStatus.active,
    this.fulfilledAt,
    this.completedContractId,
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    this.isInappropriate = false,
    this.inappropriateReason,
    this.commentCount = 0,
    this.likeCount = 0,
    this.viewCount = 0,
    this.isStandaloneAd = false,
    this.sponsorPointsSpent = 0,
    this.sponsoredUntil,
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
      itemCondition: d['itemCondition'] as String?,
      listingStatus: PostListingStatusX.fromValue(d['listingStatus'] as String?),
      fulfilledAt: (d['fulfilledAt'] as Timestamp?)?.toDate(),
      completedContractId: d['completedContractId'] as String?,
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? []),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      isInappropriate: d['isInappropriate'] as bool? ?? false,
      inappropriateReason: d['inappropriateReason'] as String?,
      commentCount: (d['commentCount'] as num?)?.toInt() ?? 0,
      likeCount: (d['likeCount'] as num?)?.toInt() ?? 0,
      viewCount: (d['viewCount'] as num?)?.toInt() ?? 0,
      isStandaloneAd: d['isStandaloneAd'] as bool? ?? false,
      sponsorPointsSpent: (d['sponsorPointsSpent'] as num?)?.toInt() ?? 0,
      sponsoredUntil: (d['sponsoredUntil'] as Timestamp?)?.toDate(),
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
  final String? itemCondition;
  final PostListingStatus listingStatus;
  final DateTime? fulfilledAt;
  final String? completedContractId;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final bool isInappropriate;
  final String? inappropriateReason;
  final int commentCount;
  final int likeCount;
  final int viewCount;
  /// A paid ad created from the ad form, not a boosted community post.
  final bool isStandaloneAd;
  final int sponsorPointsSpent;
  final DateTime? sponsoredUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Hidden from home feed and map after lend/borrow handshake.
  bool get isFulfilled => listingStatus == PostListingStatus.fulfilled;

  bool get isSponsored =>
      sponsoredUntil != null && sponsoredUntil!.isAfter(DateTime.now());

  bool get hasAdHistory =>
      isStandaloneAd || sponsorPointsSpent > 0 || sponsoredUntil != null;

  bool get isPubliclyListed => !isFulfilled;

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
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (itemCondition != null) 'itemCondition': itemCondition,
        'listingStatus': listingStatus.value,
        'imageUrls': imageUrls,
        'isInappropriate': isInappropriate,
        if (inappropriateReason != null) 'inappropriateReason': inappropriateReason,
        'commentCount': commentCount,
        'likeCount': likeCount,
        'viewCount': viewCount,
        if (isStandaloneAd) 'isStandaloneAd': true,
        if (sponsorPointsSpent > 0) 'sponsorPointsSpent': sponsorPointsSpent,
        if (sponsoredUntil != null)
          'sponsoredUntil': Timestamp.fromDate(sponsoredUntil!),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
