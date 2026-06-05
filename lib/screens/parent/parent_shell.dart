import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'children_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _index = 0;

  final _screens = const [
    ParentHomeScreen(),
    ParentMapScreen(),
    ParentChildrenScreen(),
    ParentAlertsScreen(),
    ParentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: BgColors.ink.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            selectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 11),
            unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Carte'),
              BottomNavigationBarItem(icon: Icon(Icons.family_restroom_rounded), label: 'Enfants'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alertes'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
