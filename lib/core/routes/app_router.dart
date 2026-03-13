import 'package:flutter/material.dart';

import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/splash/views/splash_view.dart';

import '../constants/app_constants.dart';

/// Central routing for Civic Citizen.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.routeSplash:
        return _buildRoute(const SplashView(), settings);
      case AppConstants.routeLogin:
        return _buildRoute(const LoginView(), settings);
      case AppConstants.routeSignup:
        return _buildRoute(const SignupView(), settings);
      case AppConstants.routeHome:
        return _buildRoute(
          Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: Text(
                  'Home (coming soon)',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
          ),
          settings,
        );
      default:
        return _buildRoute(const SplashView(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => page,
    );
  }
}

/// Global navigator key for redirects outside widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
