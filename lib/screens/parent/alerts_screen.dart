import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/alert_model.dart';
import '../../models/student_model.dart';
import '../../services/auth_service.dart';

class ParentAlertsScreen extends StatelessWidget {
  const ParentAlertsScreen({super.key});

  List<AlertModel> _buildAlerts(AuthService auth) {
    final child = auth.children.isNotEmpty ? auth.children.first : null;
    if (child == null) return [];

    return [
      if (child.status == StudentStatus.absent)
        AlertModel(
          id: '1',
          type: AlertType.absent,
          title: 'Absence signalée',
          message: '${child.firstName} a été signalé(e) absent(e) ce matin.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          childName: child.firstName,
        ),
      AlertModel(
        id: '2',
        type: AlertType.info,
        title: 'Affectation confirmée',
        message: '${child.firstName} est affecté(e) au bus ${child.busMatricule ?? '—'}.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        childName: child.firstName,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final alerts = _buildAlerts(auth);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: BgColors.dusk.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Aucune alerte', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Vous serez notifié en cas d\'événement', style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.6))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: alerts.length,
              itemBuilder: (_, i) {
                final a = alerts[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BgTheme.glassCard(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(a.icon, color: a.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(a.message, style: GoogleFonts.dmSans(fontSize: 14, color: BgColors.dusk.withValues(alpha: 0.8))),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(a.createdAt),
                              style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
