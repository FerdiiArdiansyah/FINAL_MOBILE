import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}');
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // FCM runs in background — don't block startup if it fails on web
  FCMService.initialize().catchError((e) => debugPrint('FCM init: $e'));
  runApp(const EduTechApp());
}

class EduTechApp extends StatelessWidget {
  const EduTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'EduTech SMK',
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
