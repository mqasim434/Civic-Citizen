/// Result from [LocationPickerView] — address plus coordinates for nearby search.
class LocationPickResult {
  const LocationPickResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
}
