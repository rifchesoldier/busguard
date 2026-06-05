import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/parent/parent_shell.dart';
import 'screens/driver/driver_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();

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
      theme: BgTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/parent': (_) => const ParentShell(),
        '/driver': (_) => const DriverShell(),
      },
    );
  }
}
