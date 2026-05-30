/// Whether a post still appears on the public feed and map.
enum PostListingStatus {
  active,
  fulfilled,
}

extension PostListingStatusX on PostListingStatus {
  String get value {
    switch (this) {
      case PostListingStatus.active:
        return 'active';
      case PostListingStatus.fulfilled:
        return 'fulfilled';
    }
  }

  static PostListingStatus fromValue(String? v) {
    if (v == 'fulfilled') return PostListingStatus.fulfilled;
    return PostListingStatus.active;
  }
}
