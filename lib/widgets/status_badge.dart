import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
          Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class EtaCard extends StatelessWidget {
  final int? minutes;
  final bool offline;

  const EtaCard({super.key, this.minutes, this.offline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BgTheme.glassCard(tint: BgColors.ink),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [BgColors.gold, BgColors.terracotta]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.schedule_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arrivée estimée', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
                Text(
                  offline
                      ? 'Non disponible'
                      : minutes != null
                          ? '$minutes min'
                          : 'Calcul en cours...',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
