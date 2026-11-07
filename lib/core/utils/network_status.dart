import 'dart:io';

/// Checks for a working connection without a native plugin.
class NetworkStatus {
  NetworkStatus._();

  static const offlineMessage = "You don't have internet";

  static Future<bool> get isOnline async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool isOfflineError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('network') ||
        text.contains('unavailable') ||
        text.contains('socket') ||
        text.contains('connection') ||
        text.contains('offline') ||
        text.contains('failed host lookup') ||
        text.contains('missingplugin');
  }
}
