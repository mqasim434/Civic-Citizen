import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/emailjs_config.dart';

/// Sends verification result emails via EmailJS REST API (no Firebase Functions).
class EmailJsService {
  static const _sendUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Best-effort: does nothing if [EmailJsConfig] is not filled in.
  /// Does not throw — failures are ignored so Firestore updates still succeed.
  Future<void> sendVerificationResult({
    required String toEmail,
    required String userName,
    required bool verified,
    String? rejectionReason,
  }) async {
    if (!EmailJsConfig.isConfigured) return;
    if (toEmail.isEmpty) return;

    final message = verified
        ? 'Your Civic Citizen account is verified. You can sign in and use the full app.'
        : 'We could not approve your verification at this time.${rejectionReason != null && rejectionReason.isNotEmpty ? '\n\nReason: $rejectionReason' : ''}';

    try {
      final response = await http.post(
        Uri.parse(_sendUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': EmailJsConfig.serviceId,
          'template_id': EmailJsConfig.templateId,
          'user_id': EmailJsConfig.publicKey,
          'template_params': {
            'user_email': toEmail,
            'user_name': userName,
            'message': message,
            'subject': verified ? 'Your account is verified' : 'Verification update',
          },
        }),
      );
      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('EmailJS send failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('EmailJS send error: $e');
    }
  }
}
