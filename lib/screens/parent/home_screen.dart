import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../models/student_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/child_tile.dart';
import '../../widgets/status_badge.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final _firebase = FirebaseService();
  BusModel? _bus;
  int? _eta;
  StreamSubscription? _busSub;
  Timer? _etaTimer;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  void _initTracking() {
    final auth = context.read<AuthService>();
    final child = auth.children.isNotEmpty ? auth.children.first : null;
    if (child?.busId == null) return;

    _busSub = _firebase.watchBus(child!.busId!).listen((bus) {
      if (mounted) setState(() => _bus = bus);
    });

    _etaTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshEta(child.busId!));
    _refreshEta(child.busId!);
  }

  Future<void> _refreshEta(String busId) async {
    final eta = await context.read<AuthService>().api.fetchEta(busId);
    if (mounted) setState(() => _eta = eta);
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final child = auth.children.isNotEmpty ? auth.children.first : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              decoration: BgTheme.heroGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour,', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 16)),
                  Text(
                    auth.user?.name.split(' ').first ?? 'Parent',
                    style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  if (child != null)
                    _buildChildStatus(child)
                  else
                    Text('Aucun enfant affecté pour le moment.', style: GoogleFonts.dmSans(color: Colors.white70)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_bus?.trafficAlert != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: BgColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BgColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: BgColors.danger),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Alerte trafic : ${_bus!.trafficAlert}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ],
                EtaCard(
                  minutes: _eta,
                  offline: _bus?.status == BusStatus.signalPerdu,
                ),
                const SizedBox(height: 20),
                Text('Vos enfants', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (auth.children.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BgTheme.glassCard(),
                    child: Center(
                      child: Text(
                        'En attente d\'affectation par l\'école.\nVous recevrez une notification.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.6)),
                      ),
                    ),
                  )
                else
                  ...auth.children.map((c) => ChildTile(child: c)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildStatus(StudentModel child) {
    final label = child.statusLabel;
    final color = switch (child.status) {
      StudentStatus.aBord => BgColors.success,
      StudentStatus.arrive => BgColors.sage,
      StudentStatus.absent => BgColors.danger,
      _ => BgColors.gold,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BgColors.gold,
            child: Text(child.firstName[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: BgColors.ink)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.fullName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 17)),
                Text(child.busMatricule != null ? 'Bus ${child.busMatricule}' : 'Bus non assigné', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          StatusBadge(label: label, color: color),
        ],
      ),
    );
  }
}
