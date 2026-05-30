import 'package:flutter/material.dart';

import '../../features/admin/views/admin_dashboard_view.dart';
import '../../features/admin/views/admin_user_verification_view.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/signup_view.dart';
import '../../features/home/views/main_shell.dart';
import '../../features/kyc/views/kyc_view.dart';
import '../../features/verification/views/verification_pending_view.dart';
import '../../features/verification/views/verification_rejected_view.dart';
import '../../features/lend_borrow/views/contract_detail_view.dart';
import '../../features/lend_borrow/views/contract_qr_view.dart';
import '../../features/lend_borrow/views/contract_scan_view.dart';
import '../../features/lend_borrow/views/contract_signature_view.dart';
import '../../features/posts/models/post_model.dart';
import '../../features/posts/views/create_post_view.dart';
import '../../features/posts/views/edit_post_view.dart';
import '../../features/posts/views/post_detail_view.dart';
import '../../features/settings/views/settings_view.dart';
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
      case AppConstants.routeKyc: {
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || args['uid'] == null) {
          return _buildRoute(const SplashView(), settings);
        }
        return _buildRoute(
          KycView(
            uid: args['uid'] as String,
            displayName: (args['displayName'] as String?) ?? '',
            email: (args['email'] as String?) ?? '',
          ),
          settings,
        );
      }
      case AppConstants.routeVerificationPending:
        return _buildRoute(const VerificationPendingView(), settings);
      case AppConstants.routeVerificationRejected:
        return _buildRoute(const VerificationRejectedView(), settings);
      case AppConstants.routeHome:
        return _buildRoute(const MainShell(), settings);
      case AppConstants.routeAdmin:
        return _buildRoute(const AdminDashboardView(), settings);
      case AppConstants.routeAdminUserVerification: {
        final uid = settings.arguments as String?;
        if (uid == null || uid.isEmpty) {
          return _buildRoute(const AdminDashboardView(), settings);
        }
        return _buildRoute(AdminUserVerificationView(userId: uid), settings);
      }
      case AppConstants.routePostDetail: {
        final post = settings.arguments as PostModel?;
        if (post == null) return _buildRoute(const MainShell(), settings);
        return _buildRoute(PostDetailView(post: post), settings);
      }
      case AppConstants.routeCreatePost:
        return _buildRoute(const CreatePostView(), settings);
      case AppConstants.routeEditPost: {
        final post = settings.arguments as PostModel?;
        if (post == null) return _buildRoute(const SplashView(), settings);
        return _buildRoute(EditPostView(post: post), settings);
      }
      case AppConstants.routeSettings:
        return _buildRoute(const SettingsView(), settings);
      case AppConstants.routeLendBorrowContract: {
        final contractId = settings.arguments as String?;
        if (contractId == null || contractId.isEmpty) {
          return _buildRoute(const MainShell(), settings);
        }
        return _buildRoute(ContractDetailView(contractId: contractId), settings);
      }
      case AppConstants.routeContractSignature: {
        final args = settings.arguments as Map<String, dynamic>?;
        final contractId = args?['contractId'] as String?;
        if (contractId == null) return _buildRoute(const MainShell(), settings);
        return _buildRoute(
          ContractSignatureView(
            contractId: contractId,
            isLender: args?['isLender'] as bool? ?? false,
          ),
          settings,
        );
      }
      case AppConstants.routeContractQr: {
        final contractId = settings.arguments as String?;
        if (contractId == null) return _buildRoute(const MainShell(), settings);
        return _buildRoute(ContractQrView(contractId: contractId), settings);
      }
      case AppConstants.routeContractScan: {
        final contractId = settings.arguments as String?;
        if (contractId == null) return _buildRoute(const MainShell(), settings);
        return _buildRoute(ContractScanView(contractId: contractId), settings);
      }
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
