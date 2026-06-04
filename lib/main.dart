import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'utils/constants.dart';
import 'utils/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/children_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_shell.dart';

// NOTE: Plus besoin de dart:ui_web ni dart:html
// L'iframe OpenStreetMap a été remplacé par google_maps_flutter dans dashboard_screen.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await NotificationService.instance.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const BusGuardApp(),
    ),
  );
}

class BusGuardApp extends StatelessWidget {
  const BusGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeShell(),
        '/dashboard': (_) => const DashboardScreen(),
        '/map': (_) => const MapScreen(),
        '/children': (_) => const ChildrenScreen(),
        '/alerts': (_) => const AlertsScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}