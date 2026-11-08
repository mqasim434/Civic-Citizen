import 'package:geolocator/geolocator.dart';

/// Reads a device position without waiting forever when GPS has no fix.
class DeviceLocation {
  DeviceLocation._();

  static const timeLimit = Duration(seconds: 8);

  /// A fresh fix when one arrives in time, otherwise the last known position.
  /// Null when location is off, not permitted, or no fix exists.
  static Future<Position?> current({
    Duration timeLimit = timeLimit,
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (!enabled) return _lastKnown();

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            timeLimit: timeLimit,
          ),
        ).timeout(timeLimit);
      } catch (_) {
        return _lastKnown();
      }
    } catch (_) {
      return _lastKnown();
    }
  }

  static Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {
      return null;
    }
  }
}
