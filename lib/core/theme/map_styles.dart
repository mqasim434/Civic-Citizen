import 'package:flutter/material.dart';

/// Google Map styles that match the app theme.
class MapStyles {
  MapStyles._();

  /// Style for `GoogleMap(style: ...)`. Null means Google's default (light).
  static String? forContext(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : null;

  /// Dark map tuned to the app's dark navy surfaces and green accent.
  static const String dark = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#151d2b"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#9aa3b2"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#151d2b"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#4a566a"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#c3c9d3"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#e8e4dc"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#8a93a2"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1a3328"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6fbf94"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2a374b"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#1c2738"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9aa3b2"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#2e3c52"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3b4a62"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1c2738"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#c3c9d3"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#6b7586"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#222e40"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#9aa3b2"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0b1320"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4a566a"}]}
]
''';
}
