import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/student_model.dart';
import 'status_badge.dart';

class ChildTile extends StatelessWidget {
  final StudentModel child;
  final VoidCallback? onTap;

  const ChildTile({super.key, required this.child, this.onTap});

  Color get _statusColor => switch (child.status) {
        StudentStatus.aBord => BgColors.success,
        StudentStatus.arrive => BgColors.sage,
        StudentStatus.absent => BgColors.danger,
        _ => BgColors.gold,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BgTheme.glassCard(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: BgColors.terracotta.withValues(alpha: 0.15),
              child: Text(
                child.firstName[0],
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: BgColors.terracotta),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.fullName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text(
                    '${child.className ?? '—'} · ${child.schoolName ?? 'École'}',
                    style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk.withValues(alpha: 0.7)),
                  ),
                  if (child.busMatricule != null) ...[
                    const SizedBox(height: 4),
                    Text('Bus ${child.busMatricule}', style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.sage)),
                  ],
                ],
              ),
            ),
            StatusBadge(label: child.statusLabel, color: _statusColor),
          ],
        ),
      ),
    );
  }
}
