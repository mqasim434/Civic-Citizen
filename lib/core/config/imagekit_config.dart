class ImageKitConfig {
  const ImageKitConfig({
    required this.publicKey,
    required this.urlEndpoint,
    this.privateKey,
    this.authenticationEndpoint,
  }) : assert(
         privateKey != null || authenticationEndpoint != null,
         'Provide either privateKey or authenticationEndpoint',
       );

  final String publicKey;
  final String urlEndpoint;
  final String? privateKey;
  final String? authenticationEndpoint;

  bool get useDirectAuth => privateKey != null && privateKey!.isNotEmpty;

  static ImageKitConfig get instance => const ImageKitConfig(
    publicKey: 'public_TmAJXPJQH85XW70GM8IMnncjYY8=',
    urlEndpoint: 'https://ik.imagekit.io/zqetqiw22',
    privateKey: 'private_JgefaHinFeHL50fvAuZOmv/e4kg=',
  );
}
