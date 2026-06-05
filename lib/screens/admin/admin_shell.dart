import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/bg_logo.dart';
import 'admin_buses_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_schools_screen.dart';
import 'admin_students_screen.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final isSuperAdmin = user?.role.name == 'superadmin';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── En-tête ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2A4A), Color(0xFF2D4A7A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BgLogo(size: 44, light: true),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                        tooltip: 'Déconnexion',
                        onPressed: () => _confirmLogout(context, auth),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    child: Text(
                      user?.name[0].toUpperCase() ?? 'A',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(user?.email ?? '',
                      style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSuperAdmin
                          ? BgColors.gold.withValues(alpha: 0.2)
                          : BgColors.terracotta.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSuperAdmin ? BgColors.gold : BgColors.terracotta, width: 1),
                    ),
                    child: Text(
                      isSuperAdmin ? '★ Super Admin' : 'Admin École',
                      style: GoogleFonts.dmSans(
                        color: isSuperAdmin ? BgColors.gold : BgColors.terracotta,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tableau de bord ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Tableau de bord',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.w800, color: BgColors.ink)),
                const SizedBox(height: 16),

                // Cartes stats
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.directions_bus_rounded,
                      label: 'Bus',
                      color: BgColors.terracotta,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.child_care_rounded,
                      label: 'Élèves',
                      color: BgColors.sage,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_rounded,
                      label: 'Parents',
                      color: BgColors.dusk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.person_pin_rounded,
                      label: 'Chauffeurs',
                      color: BgColors.gold,
                    ),
                  ),
                ]),

                const SizedBox(height: 28),
                Text('Actions',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.w800, color: BgColors.ink)),
                const SizedBox(height: 14),

                _AdminAction(
                  icon: Icons.directions_bus_rounded,
                  title: 'Gestion des bus',
                  subtitle: 'Ajouter, modifier ou supprimer des bus',
                  color: BgColors.terracotta,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminBusesScreen()),
                  ),
                ),
                _AdminAction(
                  icon: Icons.child_care_rounded,
                  title: 'Gestion des élèves',
                  subtitle: 'Affecter les élèves à un bus',
                  color: BgColors.sage,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminStudentsScreen()),
                  ),
                ),
                _AdminAction(
                  icon: Icons.person_pin_rounded,
                  title: 'Gestion des chauffeurs',
                  subtitle: 'Créer les comptes et identifiants chauffeurs',
                  color: BgColors.gold,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDriversScreen()),
                  ),
                ),
                if (isSuperAdmin)
                  _AdminAction(
                    icon: Icons.school_rounded,
                    title: 'Gestion des écoles',
                    subtitle: 'Administrer toutes les écoles',
                    color: const Color(0xFF2D4A7A),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminSchoolsScreen()),
                    ),
                  ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, auth),
                    icon: const Icon(Icons.logout_rounded, color: BgColors.terracotta),
                    label: Text('Déconnexion',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700, color: BgColors.terracotta)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: BgColors.terracotta),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(child: BgLogo(size: 36)),
                const SizedBox(height: 8),
                Center(
                  child: Text('BusGuard v2.0 — Administration',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: BgColors.dusk.withValues(alpha: 0.5))),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Déconnexion',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous vous déconnecter ?',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Déconnecter',
                style: TextStyle(color: BgColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('—',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: BgColors.ink)),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: BgColors.dusk.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: color.withValues(alpha: 0.06),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                color: BgColors.dusk.withValues(alpha: 0.6))),
        trailing: Icon(Icons.chevron_right_rounded, color: color),
      ),
    );
  }
}
