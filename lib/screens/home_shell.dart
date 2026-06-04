// lib/screens/home_shell.dart

import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/home_shell_navigator.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'children_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> implements HomeShellNavigator {
  int _index = 0;

  // IMPORTANT : On retire le "const" ici pour permettre aux sous-écrans 
  // d'accéder dynamiquement au Provider injecté au-dessus d'eux.
  final List<Widget> _pages = [
    const DashboardScreen(),
    const MapScreen(),
    const ChildrenScreen(),
    const AlertsScreen(),
    const ProfileScreen(),
  ];

  /// Appelé par DashboardScreen pour changer d'onglet
  @override
  void navigateTo(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    // AJOUT : On enveloppe le Scaffold avec le HomeShellProvider
    // "navigator: this" transmet directement notre State actuel (qui implémente HomeShellNavigator)
    return HomeShellProvider(
      navigator: this,
      child: Scaffold(
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.yellow.withOpacity(.3),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Tableau'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Carte'),
            NavigationDestination(
                icon: Icon(Icons.child_care_outlined),
                selectedIcon: Icon(Icons.child_care),
                label: 'Enfants'),
            NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications),
                label: 'Alertes'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }
}