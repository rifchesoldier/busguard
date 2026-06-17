import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../services/gps_service.dart';

class DriverTourScreen extends StatefulWidget {
  const DriverTourScreen({super.key});

  @override
  State<DriverTourScreen> createState() => _DriverTourScreenState();
}

class _DriverTourScreenState extends State<DriverTourScreen> {
  final _gps = GpsService();
  final _firebase = FirebaseService();
  List<BusModel> _buses = [];
  BusModel? _selectedBus;
  String _direction = 'matin';
  bool _tourActive = false;
  bool _signalLost = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    final buses = await context.read<AuthService>().api.myBuses();
    if (mounted) setState(() => _buses = buses);
  }

  Future<void> _startTour() async {
    if (_selectedBus == null) return;
    final auth = context.read<AuthService>();
    final bus = _selectedBus!;

    final granted = await _gps.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission GPS requise'), backgroundColor: BgColors.danger),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _tourActive = true;
      _signalLost = false;
    });

    _gps.startTracking(
      (pos) async {
        // Firebase → temps réel pour les parents
        await _firebase.updateBusPosition(
          busId: bus.id,
          lat: pos.latitude,
          lng: pos.longitude,
          driverId: auth.user!.id,
          driverName: auth.user!.name,
          matricule: bus.matricule,
        );
        // Laravel → persistance GPS + ETA/Directions
        await auth.api.pushDriverPosition(
          busId: bus.id,
          lat: pos.latitude,
          lng: pos.longitude,
        );
        if (mounted) setState(() => _signalLost = false);
      },
      onSignalLost: () {
        if (mounted) setState(() => _signalLost = true);
      },
    );

    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final pos = _gps.lastPosition;
      if (pos == null || !mounted) return;
      await _firebase.updateBusPosition(
        busId: bus.id,
        lat: pos.latitude,
        lng: pos.longitude,
        driverId: auth.user!.id,
        driverName: auth.user!.name,
        matricule: bus.matricule,
        status: _signalLost ? 'signal_perdu' : 'en_route',
      );
      // Sync Laravel aussi (pour ETA côté proxy Directions)
      await auth.api.pushDriverPosition(
        busId: bus.id,
        lat: pos.latitude,
        lng: pos.longitude,
        status: _signalLost ? 'signal_perdu' : 'en_route',
      );
    });
  }

  Future<void> _stopTour() async {
    _gps.stopTracking();
    _updateTimer?.cancel();
    setState(() => _tourActive = false);
  }

  @override
  void dispose() {
    _gps.stopTracking();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [BgColors.ink, BgColors.dusk],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Espace Chauffeur', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Activez votre tournée pour démarrer le suivi GPS', style: GoogleFonts.dmSans(color: Colors.white70)),
                  if (_tourActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (_signalLost ? BgColors.danger : BgColors.success).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Icon(_signalLost ? Icons.gps_off : Icons.gps_fixed, color: _signalLost ? BgColors.danger : BgColors.success),
                          const SizedBox(width: 10),
                          Text(
                            _signalLost ? 'Signal GPS perdu' : 'GPS actif — mise à jour toutes les 3s',
                            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Sélectionnez votre véhicule', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._buses.map((bus) => _BusSelectCard(
                      bus: bus,
                      selected: _selectedBus?.id == bus.id,
                      onTap: _tourActive ? null : () => setState(() => _selectedBus = bus),
                    )),
                if (_buses.isEmpty)
                  Text('Aucun bus affecté. Contactez l\'administrateur.', style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.6))),
                const SizedBox(height: 24),
                Text('Type de tournée', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _DirectionChip(label: 'Matin', icon: Icons.wb_sunny_rounded, selected: _direction == 'matin', onTap: () => setState(() => _direction = 'matin'))),
                    const SizedBox(width: 12),
                    Expanded(child: _DirectionChip(label: 'Soir', icon: Icons.nights_stay_rounded, selected: _direction == 'soir', onTap: () => setState(() => _direction = 'soir'))),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _selectedBus == null ? null : (_tourActive ? _stopTour : _startTour),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tourActive ? BgColors.danger : BgColors.gold,
                      foregroundColor: BgColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      _tourActive ? 'ARRÊTER LA TOURNÉE' : 'DÉMARRER LA TOURNÉE',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1),
                    ),
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

class _BusSelectCard extends StatelessWidget {
  final BusModel bus;
  final bool selected;
  final VoidCallback? onTap;

  const _BusSelectCard({required this.bus, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? BgColors.gold.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? BgColors.gold : BgColors.dusk.withValues(alpha: 0.1), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            const Text('🚌', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bus.matricule, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
                  Text('${bus.model ?? 'Bus'} · ${bus.capacity} places', style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk.withValues(alpha: 0.6))),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: BgColors.gold),
          ],
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DirectionChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? BgColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? BgColors.ink : BgColors.dusk.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? BgColors.gold : BgColors.dusk, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: selected ? Colors.white : BgColors.ink)),
          ],
        ),
      ),
    );
  }
}
