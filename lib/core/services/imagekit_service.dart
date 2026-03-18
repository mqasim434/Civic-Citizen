import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/imagekit_config.dart';

/// ImageKit upload service — replaces Firebase Storage.
class ImageKitService {
  ImageKitService(this._config);

  final ImageKitConfig _config;

  static const _uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

  /// Upload image and return the CDN URL.
  Future<String> upload({
    required File file,
    required String folder,
    String? fileName,
  }) async {
    final fn = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    if (_config.useDirectAuth) {
      // Server-side: Basic auth uses privateKey: (private key + colon, empty password).
      // See: https://docs.imagekit.io/api-reference/upload-file-api/server-side-file-upload
      final credentials = '${_config.privateKey!}:';
      request.headers['Authorization'] = 'Basic ${_credentialsToBase64(credentials)}';
      request.fields['fileName'] = fn;
      request.fields['folder'] = folder;
      request.fields['useUniqueFileName'] = 'true';
    } else {
      // Client-side: needs signature from auth endpoint.
      final auth = await _getAuth();
      if (auth == null) {
        throw Exception('Failed to get ImageKit auth. Check your auth endpoint.');
      }
      request.fields['publicKey'] = _config.publicKey;
      request.fields['signature'] = auth['signature'] as String;
      request.fields['expire'] = auth['expire'].toString();
      request.fields['token'] = auth['token'] as String;
      request.fields['fileName'] = fn;
      request.fields['folder'] = folder;
      request.fields['useUniqueFileName'] = 'true';
    }

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      String message;
      try {
        final body = jsonDecode(response.body);
        message = body['message'] as String? ?? body['error'] as String? ?? 'Upload failed';
      } catch (_) {
        message = 'ImageKit upload failed: ${response.statusCode}';
      }
      if (message.toLowerCase().contains('authenticated')) {
        message = '$message. Check that your ImageKit private key in lib/core/config/imagekit_config.dart is correct (from imagekit.io dashboard).';
      }
      throw Exception(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('ImageKit did not return URL');
    }
    return url;
  }

  String _credentialsToBase64(String credentials) {
    return base64Encode(utf8.encode(credentials));
  }

  Future<Map<String, dynamic>?> _getAuth() async {
    final endpoint = _config.authenticationEndpoint;
    if (endpoint == null || endpoint.isEmpty) return null;
    try {
      final uri = Uri.parse(endpoint);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Auth endpoint timeout'),
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'token': data['token'] as String?,
        'expire': data['expire'],
        'signature': data['signature'] as String?,
      };
    } catch (_) {
      return null;
    }
  }
}
