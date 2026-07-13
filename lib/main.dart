import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routes/app_router.dart';
import 'features/announcements/widgets/announcement_listener.dart';
import 'core/services/announcement_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/admin/services/admin_service.dart';
import 'features/admin/services/legal_export_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';
import 'features/kyc/controllers/kyc_controller.dart';
import 'features/kyc/services/kyc_service.dart';
import 'features/lend_borrow/services/lend_borrow_contract_service.dart';
import 'features/lost_found/services/lost_found_claim_service.dart';
import 'features/mutual_confidence/services/contact_request_service.dart';
import 'features/mutual_confidence/services/trust_profile_service.dart';
import 'features/posts/controllers/post_controller.dart';
import 'features/posts/services/post_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final pushService = PushNotificationService();
  await pushService.initialize();
  runApp(CivicCitizenApp(prefs: prefs, pushService: pushService));
}

class CivicCitizenApp extends StatelessWidget {
  const CivicCitizenApp({
    super.key,
    required this.prefs,
    required this.pushService,
  });

  final SharedPreferences prefs;
  final PushNotificationService pushService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(ctx.read<AuthService>()),
        ),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<AnnouncementService>(create: (_) => AnnouncementService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<PushNotificationService>.value(value: pushService),
        Provider<KycService>(
          create: (ctx) => KycService(
            notifications: ctx.read<NotificationService>(),
            trustProfiles: ctx.read<TrustProfileService>(),
          ),
        ),
        Provider<AdminService>(
          create: (ctx) => AdminService(
            notifications: ctx.read<NotificationService>(),
            trustProfiles: ctx.read<TrustProfileService>(),
          ),
        ),
        Provider<LegalExportService>(create: (_) => LegalExportService()),
        Provider<TrustProfileService>(create: (_) => TrustProfileService()),
        ChangeNotifierProvider<KycController>(
          create: (ctx) => KycController(ctx.read<KycService>()),
        ),
        Provider<PostService>(create: (_) => PostService()),
        Provider<LendBorrowContractService>(
          create: (ctx) => LendBorrowContractService(
            notifications: ctx.read<NotificationService>(),
            trustProfiles: ctx.read<TrustProfileService>(),
          ),
        ),
        Provider<LostFoundClaimService>(
          create: (ctx) => LostFoundClaimService(
            notifications: ctx.read<NotificationService>(),
            trustProfiles: ctx.read<TrustProfileService>(),
          ),
        ),
        Provider<ContactRequestService>(
          create: (ctx) => ContactRequestService(
            notifications: ctx.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<PostController>(
          create: (ctx) => PostController(ctx.read<PostService>()),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(prefs),
        ),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          pushService.bindUser(auth.user?.uid);
          return Consumer<ThemeController>(
            builder: (_, themeCtrl, __) => MaterialApp(
              title: 'Civic Citizen',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeCtrl.mode,
              navigatorKey: navigatorKey,
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: '/',
              builder: (context, child) =>
                  AnnouncementListener(child: child),
            ),
          );
        },
      ),
    );
  }
}
