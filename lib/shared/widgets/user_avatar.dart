import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/mutual_confidence/models/public_trust_profile.dart';
import '../../features/mutual_confidence/services/trust_profile_service.dart';

/// Circle avatar for any community member. Shows their profile photo when
/// they have one, otherwise the first letter of their name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.radius = 18,
    this.photoUrl,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String userId;
  final String name;
  final double radius;

  /// Use when the photo URL is already known (skips the lookup).
  final String? photoUrl;

  final Color? backgroundColor;
  final Color? foregroundColor;

  String? _nonEmpty(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final direct = _nonEmpty(photoUrl);
    if (direct != null) return _avatar(context, direct);

    final signedIn = context.watch<AuthController>().user;
    final ownPhoto =
        signedIn != null && signedIn.uid == userId ? _nonEmpty(signedIn.photoUrl) : null;
    if (userId.isEmpty) return _avatar(context, ownPhoto);

    return StreamBuilder<PublicTrustProfile?>(
      stream: context.read<TrustProfileService>().watchProfile(userId),
      builder: (context, snap) =>
          _avatar(context, _nonEmpty(snap.data?.photoUrl) ?? ownPhoto),
    );
  }

  Widget _avatar(BuildContext context, String? url) {
    final theme = Theme.of(context);
    final hasPhoto = url != null && url.isNotEmpty;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
      foregroundImage: hasPhoto ? NetworkImage(url) : null,
      onForegroundImageError: hasPhoto ? (_, __) {} : null,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w700,
          color: foregroundColor ?? theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
