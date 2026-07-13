import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/notification_service.dart';
import '../../features/auth/controllers/auth_controller.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: context.read<NotificationService>().watchUnreadCount(user.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return IconButton(
              tooltip: 'Notifications unavailable',
              onPressed: () => navigatorKey.currentState?.pushNamed(
                AppConstants.routeNotifications,
              ),
              icon: const Icon(Icons.notifications_off_outlined),
            );
          }
          final count = snap.data ?? 0;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => navigatorKey.currentState?.pushNamed(
            AppConstants.routeNotifications,
          ),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
