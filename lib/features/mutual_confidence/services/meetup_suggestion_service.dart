import 'package:geolocator/geolocator.dart';

import '../../posts/models/post_model.dart';
import '../../posts/utils/post_search_filter.dart';
import '../models/meetup_suggestion.dart';

/// Client-side safe meetup suggestions — no Places API required.
class MeetupSuggestionService {
  MeetupSuggestionService._();

  static Future<List<MeetupSuggestion>> suggestionsForPost(
    PostModel post,
  ) async {
    final listingCoords = PostSearchFilter.coordinatesFor(post);
    Position? userPosition;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        userPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      }
    } catch (_) {}

    final suggestions = <MeetupSuggestion>[];
    final locationLabel = post.location?.trim();

    if (listingCoords != null) {
      final distanceText = userPosition != null
          ? PostSearchFilter.formatDistanceKm(
              PostSearchFilter.distanceKm(
                userPosition.latitude,
                userPosition.longitude,
                listingCoords.lat,
                listingCoords.lng,
              ),
            )
          : null;
      suggestions.add(
        MeetupSuggestion(
          label: 'Near listing location',
          description: [
            if (locationLabel != null && locationLabel.isNotEmpty) locationLabel,
            if (distanceText != null) distanceText,
            'Choose a busy, well-lit public spot close to this area.',
          ].where((e) => e.isNotEmpty).join(' · '),
          latitude: listingCoords.lat,
          longitude: listingCoords.lng,
        ),
      );

      if (userPosition != null) {
        final midLat =
            (userPosition.latitude + listingCoords.lat) / 2;
        final midLng =
            (userPosition.longitude + listingCoords.lng) / 2;
        final midDistance = PostSearchFilter.formatDistanceKm(
          PostSearchFilter.distanceKm(
            userPosition.latitude,
            userPosition.longitude,
            midLat,
            midLng,
          ),
        );
        suggestions.add(
          MeetupSuggestion(
            label: 'Midpoint between you and listing',
            description:
                '$midDistance — meet at a public café, mall, or community center in this area.',
            latitude: midLat,
            longitude: midLng,
          ),
        );
      }
    } else if (locationLabel != null && locationLabel.isNotEmpty) {
      suggestions.add(
        MeetupSuggestion(
          label: 'Near listed address',
          description:
              '$locationLabel — pick a visible public place such as a market entrance or main road junction.',
        ),
      );
    }

    suggestions.add(
      const MeetupSuggestion(
        label: 'Busy public area',
        description:
            'Meet during daylight at a crowded spot — police station forecourt, hospital entrance, or shopping plaza.',
      ),
    );

    return suggestions;
  }

  static List<MeetupSuggestion> suggestionsFromCoordinates({
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) {
    if (latitude != null && longitude != null) {
      return [
        MeetupSuggestion(
          label: 'Near agreed location',
          description: [
            if (locationLabel != null && locationLabel.trim().isNotEmpty)
              locationLabel.trim(),
            'Choose a well-lit public spot with foot traffic.',
          ].where((e) => e.isNotEmpty).join(' · '),
          latitude: latitude,
          longitude: longitude,
        ),
        const MeetupSuggestion(
          label: 'Busy public area',
          description:
              'Police station forecourt, hospital entrance, or shopping plaza during daylight hours.',
        ),
      ];
    }
    if (locationLabel != null && locationLabel.trim().isNotEmpty) {
      return [
        MeetupSuggestion(
          label: 'Near listed address',
          description:
              '${locationLabel.trim()} — meet at a visible public landmark nearby.',
        ),
        const MeetupSuggestion(
          label: 'Busy public area',
          description:
              'Choose a crowded, well-lit location and tell the other party exactly where to wait.',
        ),
      ];
    }
    return const [
      MeetupSuggestion(
        label: 'Busy public area',
        description:
            'Meet during daylight at a crowded spot — police station forecourt, hospital entrance, or shopping plaza.',
      ),
    ];
  }
}
