import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import 'tour_screen.dart';
import 'attendance_screen.dart';
import 'incident_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  final _screens = const [
    DriverTourScreen(),
    DriverAttendanceScreen(),
    DriverIncidentScreen(),
  ];

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Déconnexion', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous vous déconnecter ?', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthService>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Déconnecter', style: TextStyle(color: BgColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: BgColors.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BusGuard', style: GoogleFonts.outfit(color: BgColors.gold, fontWeight: FontWeight.w800, fontSize: 18)),
            Text(user?.name ?? 'Chauffeur', style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Déconnexion',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: BgColors.ink,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BottomNavigationBar(
            backgroundColor: BgColors.ink,
            selectedItemColor: BgColors.gold,
            unselectedItemColor: Colors.white54,
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            selectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill_rounded, size: 28), label: 'Tournée'),
              BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded, size: 28), label: 'Présences'),
              BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded, size: 28), label: 'Incidents'),
            ],
          ),
        ),
      ),
    );
  }
}
