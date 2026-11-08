import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/announcement_service.dart';
import '../../admin/services/admin_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'announcement_dialog.dart';

/// Shows each active broadcast popup at most once per user.
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
  final Set<String> _sessionShownIds = {};

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

  void _scheduleCheck({Duration delay = _routePollDelay}) {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      await Future<void>.delayed(delay);
      if (!mounted) return;
      await _checkIfNeeded();
    });
  }

  /// Routes where a broadcast popup must not appear.
  bool _isExcludedRoute(String? routeName) {
    return routeName == null ||
        routeName == AppConstants.routeSplash ||
        routeName == AppConstants.routeLogin ||
        routeName == AppConstants.routeSignup ||
        routeName == AppConstants.routeKyc ||
        routeName == AppConstants.routeVerificationPending ||
        routeName == AppConstants.routeVerificationRejected ||
        routeName == AppConstants.routeAccountBanned;
  }

  /// The navigator's own context is above the current page, so
  /// [ModalRoute.of] cannot see login or signup. Read the top route instead.
  String? _topRouteName() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return null;
    Route<dynamic>? top;
    navigator.popUntil((route) {
      top = route;
      return true;
    });
    return top?.settings.name;
  }

  void _waitForAllowedRoute() {
    _routeWaitAttempts++;
    _scheduleCheck(
      delay: _routeWaitAttempts < _maxRouteWaitAttempts
          ? _routePollDelay
          : const Duration(seconds: 2),
    );
  }

  Future<void> _checkIfNeeded() async {
    final user = context.read<AuthController>().user;
    if (user == null) {
      _handledUserId = null;
      _routeWaitAttempts = 0;
      _sessionShownIds.clear();
      return;
    }
    if (_running || _handledUserId == user.uid) return;

    if (_isExcludedRoute(_topRouteName())) {
      _waitForAllowedRoute();
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
      final toShow = pending
          .where((a) => !_sessionShownIds.contains(a.id))
          .toList();
      if (toShow.isEmpty) {
        _handledUserId = user.uid;
        return;
      }

      await Future<void>.delayed(_showDelay);
      if (!mounted) return;
      if (context.read<AuthController>().user?.uid != user.uid) return;
      if (_isExcludedRoute(_topRouteName())) {
        _waitForAllowedRoute();
        return;
      }

      var leftAllowedRoute = false;
      for (final announcement in toShow) {
        if (!mounted) break;
        if (context.read<AuthController>().user?.uid != user.uid ||
            _isExcludedRoute(_topRouteName())) {
          leftAllowedRoute = true;
          break;
        }

        // Mark seen before showing so force-close / crash never re-pops it.
        _sessionShownIds.add(announcement.id);
        try {
          await announcementService.markSeen(user.uid, announcement.id);
        } catch (e, st) {
          debugPrint('Failed to mark broadcast seen: $e\n$st');
        }
        if (!mounted) break;

        final dialogContext = navigatorKey.currentContext;
        if (dialogContext == null || !dialogContext.mounted) break;

        await showAnnouncementDialog(dialogContext, announcement);
      }
      if (leftAllowedRoute) {
        _waitForAllowedRoute();
      } else if (mounted &&
          context.read<AuthController>().user?.uid == user.uid) {
        _handledUserId = user.uid;
      }
    } catch (e, st) {
      debugPrint('AnnouncementListener failed: $e\n$st');
      if (_routeWaitAttempts++ < 3) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) {
          _handledUserId = null;
          _scheduleCheck();
        }
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
