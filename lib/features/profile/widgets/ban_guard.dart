import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/profile_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Redirects banned users away from the main app shell.
class BanGuard extends StatelessWidget {
  const BanGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return child;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: context.read<ProfileService>().watchProfile(user.uid),
      builder: (context, snap) {
        if (ProfileService.isBanned(snap.data)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final nav = navigatorKey.currentState;
            if (nav == null) return;
            final current = ModalRoute.of(context)?.settings.name;
            if (current != AppConstants.routeAccountBanned) {
              nav.pushReplacementNamed(AppConstants.routeAccountBanned);
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child;
      },
    );
  }
}
