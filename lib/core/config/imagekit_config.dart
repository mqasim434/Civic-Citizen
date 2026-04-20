class ImageKitConfig {
  const ImageKitConfig({
    required this.publicKey,
    required this.urlEndpoint,
    this.privateKey,
    this.authenticationEndpoint,
  });

  final String publicKey;
  final String urlEndpoint;
  final String? privateKey;
  final String? authenticationEndpoint;

  bool get useDirectAuth => privateKey != null && privateKey!.isNotEmpty;
  bool get hasAuthEndpoint =>
      authenticationEndpoint != null && authenticationEndpoint!.isNotEmpty;
  bool get isConfigured =>
      publicKey.isNotEmpty &&
      urlEndpoint.isNotEmpty &&
      (useDirectAuth || hasAuthEndpoint);

  static ImageKitConfig get instance => ImageKitConfig(
    publicKey: const String.fromEnvironment('IMAGEKIT_PUBLIC_KEY'),
    urlEndpoint: const String.fromEnvironment('IMAGEKIT_URL_ENDPOINT'),
    privateKey: _nullableEnv('IMAGEKIT_PRIVATE_KEY'),
    authenticationEndpoint: _nullableEnv('IMAGEKIT_AUTH_ENDPOINT'),
  );

  static String? _nullableEnv(String key) {
    final value = String.fromEnvironment(key);
    if (value.isNotEmpty) return value;
    return null;
  }
}
