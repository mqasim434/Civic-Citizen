import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/admin/services/admin_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';
import 'features/kyc/controllers/kyc_controller.dart';
import 'features/kyc/services/kyc_service.dart';
import 'features/posts/controllers/post_controller.dart';
import 'features/posts/services/post_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  runApp(CivicCitizenApp(prefs: prefs));
}

class CivicCitizenApp extends StatelessWidget {
  const CivicCitizenApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(ctx.read<AuthService>()),
        ),
        Provider<KycService>(create: (_) => KycService()),
        Provider<AdminService>(create: (_) => AdminService()),
        ChangeNotifierProvider<KycController>(
          create: (ctx) => KycController(ctx.read<KycService>()),
        ),
        Provider<PostService>(create: (_) => PostService()),
        ChangeNotifierProvider<PostController>(
          create: (ctx) => PostController(ctx.read<PostService>()),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(prefs),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (_, themeCtrl, __) => MaterialApp(
          title: 'Civic Citizen',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeCtrl.mode,
          navigatorKey: navigatorKey,
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: '/',
        ),
      ),
    );
  }
}
