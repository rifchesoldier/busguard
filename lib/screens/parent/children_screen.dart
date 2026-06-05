import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/child_tile.dart';

class ParentChildrenScreen extends StatelessWidget {
  const ParentChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes enfants')),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshChildren(),
        color: BgColors.terracotta,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [BgColors.sage.withValues(alpha: 0.2), BgColors.gold.withValues(alpha: 0.15)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: BgColors.sage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'L\'affectation bus/arrêt est gérée par l\'administrateur scolaire.',
                      style: GoogleFonts.dmSans(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            if (auth.children.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.child_care_rounded, size: 64, color: BgColors.dusk.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('Aucun enfant enregistré', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Contactez l\'école pour l\'inscription', style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              )
            else
              ...auth.children.map((c) => ChildTile(child: c)),
          ],
        ),
      ),
    );
  }
}
