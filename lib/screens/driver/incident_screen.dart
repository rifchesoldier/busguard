import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';

class DriverIncidentScreen extends StatefulWidget {
  const DriverIncidentScreen({super.key});

  @override
  State<DriverIncidentScreen> createState() => _DriverIncidentScreenState();
}

class _DriverIncidentScreenState extends State<DriverIncidentScreen> {
  final _firebase = FirebaseService();
  String? _activeIncident;
  bool _loading = false;
  String _busId = '1';

  Future<void> _report(String type) async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final buses = await auth.api.myBuses();
      if (buses.isNotEmpty) _busId = buses.first.id;

      await auth.api.reportTraffic(busId: _busId, type: type);
      await _firebase.setTrafficAlert(_busId, type);
      if (mounted) {
        setState(() => _activeIncident = type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alerte envoyée aux parents'), backgroundColor: BgColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: BgColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.api.reportTraffic(busId: _busId, type: 'embouteillage', resolved: true);
      await _firebase.setTrafficAlert(_busId, null);
      if (mounted) setState(() => _activeIncident = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _activeIncident != null
                      ? [BgColors.danger, BgColors.terracotta]
                      : [BgColors.dusk, BgColors.ink],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signalement d\'incident', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    _activeIncident != null
                        ? 'Incident actif : $_activeIncident'
                        : 'Signalez rapidement une perturbation',
                    style: GoogleFonts.dmSans(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_activeIncident != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: BgColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BgColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: BgColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text('Les parents ont été notifiés', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _resolve,
                            style: ElevatedButton.styleFrom(backgroundColor: BgColors.success),
                            child: const Text('Marquer comme résolu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _IncidentButton(
                  icon: Icons.traffic_rounded,
                  label: 'Embouteillage',
                  subtitle: 'Trafic dense, retard possible',
                  color: BgColors.gold,
                  onTap: _loading ? null : () => _report('embouteillage'),
                ),
                _IncidentButton(
                  icon: Icons.car_crash_rounded,
                  label: 'Accident',
                  subtitle: 'Incident sur la route',
                  color: BgColors.danger,
                  onTap: _loading ? null : () => _report('accident'),
                ),
                _IncidentButton(
                  icon: Icons.build_circle_rounded,
                  label: 'Panne technique',
                  subtitle: 'Problème mécanique du bus',
                  color: BgColors.terracotta,
                  onTap: _loading ? null : () => _report('panne'),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: BgColors.sage.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: BgColors.sage),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Une notification push est envoyée à tous les parents du bus.', style: GoogleFonts.dmSans(fontSize: 13))),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _IncidentButton({required this.icon, required this.label, required this.subtitle, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(subtitle, style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
