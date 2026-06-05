import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/bg_logo.dart';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
              decoration: BgTheme.heroGradient,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white24,
                    child: Text(
                      user?.name[0] ?? 'P',
                      style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user?.name ?? '', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(user?.email ?? '', style: GoogleFonts.dmSans(color: Colors.white70)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileTile(icon: Icons.phone_outlined, label: 'Téléphone', value: user?.phone ?? 'Non renseigné'),
                _ProfileTile(icon: Icons.verified_user_outlined, label: 'Rôle', value: 'Parent'),
                const SizedBox(height: 24),
                _ActionButton(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Supprimer mon compte',
                  color: BgColors.danger,
                  onTap: () => _confirmDelete(context, auth),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: BgColors.terracotta),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text('Déconnexion', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: BgColors.terracotta)),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(child: BgLogo(size: 40)),
                const SizedBox(height: 8),
                Center(child: Text('BusGuard v2.0 — Dakar', style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.5)))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer le compte ?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Cette action est irréversible (droit à l\'oubli).', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: BgColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BgTheme.glassCard(),
      child: Row(
        children: [
          Icon(icon, color: BgColors.terracotta),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.6))),
              Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color = BgColors.ink});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
