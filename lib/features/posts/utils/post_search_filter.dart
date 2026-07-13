import 'dart:math' as math;

import '../models/post_model.dart';

/// Client-side keyword, category, and radius filtering for posts.
class PostSearchFilter {
  PostSearchFilter._();

  static const radiusOptionsKm = <double>[1, 3, 5, 10];

  /// Default radius for the Nearby tab (proposal: 1–5 km).
  static const double defaultNearbyRadiusKm = 5;

  /// Posts within [radiusKm] of the user, sorted nearest first.
  static List<({PostModel post, double distanceKm})> nearbyPosts({
    required List<PostModel> posts,
    required double userLatitude,
    required double userLongitude,
    required double radiusKm,
    PostModule? module,
  }) {
    final results = <({PostModel post, double distanceKm})>[];
    for (final post in posts) {
      if (!post.isPubliclyListed || post.isInappropriate) continue;
      if (module != null && post.module != module) continue;
      final coords = coordinatesFor(post);
      if (coords == null) continue;
      final d = distanceKm(
        userLatitude,
        userLongitude,
        coords.lat,
        coords.lng,
      );
      if (d <= radiusKm) {
        results.add((post: post, distanceKm: d));
      }
    }
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  static String formatDistanceKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  static List<PostModel> apply({
    required List<PostModel> posts,
    String keyword = '',
    String? category,
    double? radiusKm,
    double? userLatitude,
    double? userLongitude,
  }) {
    var result = posts
        .where((p) => p.isPubliclyListed && !p.isInappropriate)
        .toList();

    final q = keyword.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((p) => _matchesKeyword(p, q)).toList();
    }

    if (category != null && category.isNotEmpty) {
      result =
          result.where((p) => p.categoryDisplayLabel == category).toList();
    }

    if (radiusKm != null &&
        radiusKm > 0 &&
        userLatitude != null &&
        userLongitude != null) {
      result = result.where((p) {
        final coords = coordinatesFor(p);
        if (coords == null) return false;
        return distanceKm(
              userLatitude,
              userLongitude,
              coords.lat,
              coords.lng,
            ) <=
            radiusKm;
      }).toList();
    }

    return result;
  }

  static List<String> categoriesFromPosts(List<PostModel> posts) {
    final set = <String>{};
    for (final post in posts) {
      final label = post.categoryDisplayLabel?.trim();
      if (label != null && label.isNotEmpty) set.add(label);
    }
    final list = set.toList()..sort();
    return list;
  }

  static ({double lat, double lng})? coordinatesFor(PostModel post) {
    if (post.latitude != null && post.longitude != null) {
      return (lat: post.latitude!, lng: post.longitude!);
    }
    return _parseLatLngFromLocation(post.location);
  }

  static bool _matchesKeyword(PostModel post, String q) {
    final haystack = [
      post.title,
      post.description,
      post.location ?? '',
      post.categoryDisplayLabel ?? '',
      post.category ?? '',
      post.authorName,
      post.module.label,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  static ({double lat, double lng})? _parseLatLngFromLocation(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return (lat: lat, lng: lng);
  }

  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double deg) => deg * math.pi / 180;
}
