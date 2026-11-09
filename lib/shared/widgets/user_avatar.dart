import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null || userId.isEmpty) {
      return _avatar(context, photoUrl);
    }
    return StreamBuilder<PublicTrustProfile?>(
      stream: context.read<TrustProfileService>().watchProfile(userId),
      builder: (context, snap) => _avatar(context, snap.data?.photoUrl),
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
