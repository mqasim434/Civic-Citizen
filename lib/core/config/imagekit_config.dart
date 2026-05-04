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
    publicKey: 'public_TmAJXPJQH85XW70GM8IMnncjYY8=',
    urlEndpoint: 'https://ik.imagekit.io/zqetqiw22',
    privateKey: 'private_JgefaHinFeHL50fvAuZOmv/e4kg=',
    authenticationEndpoint: null,
  );
}
