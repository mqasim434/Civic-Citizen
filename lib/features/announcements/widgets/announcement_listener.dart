import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/announcement_service.dart';
import '../../admin/services/admin_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'announcement_dialog.dart';

/// Shows undismissed admin broadcasts after login / app start.
class AnnouncementListener extends StatefulWidget {
  const AnnouncementListener({super.key, this.child});

  final Widget? child;

  @override
  State<AnnouncementListener> createState() => _AnnouncementListenerState();
}

class _AnnouncementListenerState extends State<AnnouncementListener> {
  String? _handledUserId;
  bool _running = false;
  bool _scheduled = false;
  int _routeWaitAttempts = 0;

  static const _maxRouteWaitAttempts = 40;
  static const _routePollDelay = Duration(milliseconds: 500);
  static const _showDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    context.read<AuthController>().addListener(_scheduleCheck);
    _scheduleCheck();
  }

  @override
  void dispose() {
    context.read<AuthController>().removeListener(_scheduleCheck);
    super.dispose();
  }

  @override
  void didUpdateWidget(AnnouncementListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      await Future<void>.delayed(_routePollDelay);
      if (!mounted) return;
      await _checkIfNeeded();
    });
  }

  bool _isExcludedRoute(String? routeName) {
    return routeName == AppConstants.routeSplash ||
        routeName == AppConstants.routeLogin ||
        routeName == AppConstants.routeSignup ||
        routeName == AppConstants.routeKyc;
  }

  Future<void> _checkIfNeeded() async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      _handledUserId = null;
      _routeWaitAttempts = 0;
      return;
    }
    if (_running || _handledUserId == user.uid) return;

    final navContext = navigatorKey.currentContext;
    if (navContext == null) {
      if (_routeWaitAttempts++ < _maxRouteWaitAttempts) _scheduleCheck();
      return;
    }

    final routeName = ModalRoute.of(navContext)?.settings.name;
    if (_isExcludedRoute(routeName)) {
      if (_routeWaitAttempts++ < _maxRouteWaitAttempts) _scheduleCheck();
      return;
    }

    _routeWaitAttempts = 0;

    _running = true;
    final announcementService = context.read<AnnouncementService>();
    try {
      if (await context.read<AdminService>().isAdmin(user.uid)) {
        _handledUserId = user.uid;
        return;
      }

      final pending = await announcementService.getPendingForUser(user.uid);
      if (pending.isEmpty) {
        _handledUserId = user.uid;
        return;
      }

      await Future<void>.delayed(_showDelay);
      if (!mounted) return;

      _handledUserId = user.uid;

      for (final announcement in pending) {
        final dialogContext = navigatorKey.currentContext;
        if (dialogContext == null || !dialogContext.mounted) break;

        await showAnnouncementDialog(dialogContext, announcement);

        if (!mounted) break;
        await announcementService.dismiss(user.uid, announcement.id);
      }
    } catch (e, st) {
      debugPrint('AnnouncementListener failed: $e\n$st');
      if (_routeWaitAttempts++ < 3) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) _scheduleCheck();
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
