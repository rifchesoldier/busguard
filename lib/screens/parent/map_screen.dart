import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../models/student_model.dart';
import '../../services/auth_service.dart';
import '../../services/directions_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/status_badge.dart' show EtaCard;

class ParentMapScreen extends StatefulWidget {
  const ParentMapScreen({super.key});

  @override
  State<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends State<ParentMapScreen> {
  GoogleMapController? _mapController;
  final _firebase = FirebaseService();

  BusModel? _bus;
  StudentModel? _child;
  StreamSubscription? _busSub;
  Timer? _etaTimer;
  int? _eta;
  bool _offline = false;

  static const _schoolLatLng = LatLng(14.7392, -17.5123);
  static const _dakarLatLng  = LatLng(AppConstants.dakarLat, AppConstants.dakarLng);

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _init();
    Connectivity().onConnectivityChanged.listen((r) {
      if (mounted) setState(() => _offline = r.contains(ConnectivityResult.none));
    });
  }

  void _init() {
    final auth = context.read<AuthService>();
    _child = auth.children.isNotEmpty ? auth.children.first : null;

    // Marqueur école toujours visible
    _markers = {
      Marker(
        markerId: const MarkerId('school'),
        position: _schoolLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'École'),
      ),
    };

    if (_child?.busId == null) return;

    _busSub = _firebase.watchBus(_child!.busId!).listen((bus) {
      if (!mounted || bus?.position == null) return;
      setState(() => _bus = bus);
      _updateMapOverlays(bus!);
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(bus!.position!.lat, bus.position!.lng)),
      );
    });

    _etaTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_child?.busId != null) _refreshEta(_child!.busId!);
    });
    _refreshEta(_child!.busId!);
  }

  /// Appelle Google Directions via le backend (proxy) pour éviter CORS.
  Future<void> _updateMapOverlays(BusModel bus) async {
    final busPos = LatLng(bus.position!.lat, bus.position!.lng);

    // Marqueurs bus + école
    final newMarkers = {
      Marker(
        markerId: const MarkerId('bus'),
        position: busPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          bus.trafficAlert != null ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(
          title: 'Bus ${bus.matricule}',
          snippet: bus.statusLabel,
        ),
      ),
      Marker(
        markerId: const MarkerId('school'),
        position: _schoolLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'École'),
      ),
    };

    // Appel via backend Laravel → Google Directions (pas de CORS)
    final token = context.read<AuthService>().user?.token;
    List<LatLng>? routePoints;
    if (token != null) {
      routePoints = await DirectionsService.getRouteForBus(
        busId: bus.id,
        token: token,
      );
    }

    // Fallback ligne droite si indisponible
    final polylinePoints = (routePoints != null && routePoints.length > 1)
        ? routePoints
        : [busPos, _schoolLatLng];

    final newPolylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: BgColors.terracotta,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
      });
    }
  }

  Future<void> _refreshEta(String busId) async {
    final eta = await context.read<AuthService>().api.fetchEta(busId);
    if (mounted) setState(() => _eta = eta);
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _etaTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    final pos = _bus?.position;
    final notStarted = _bus == null || _bus!.status == BusStatus.idle;
    final signalLost = _bus?.status == BusStatus.signalPerdu;

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: const CameraPosition(
              target: _dakarLatLng,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
          ),

          // ── Bannière hors-ligne ───────────────────────────────────────
          if (_offline)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Material(
                color: BgColors.gold,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Text(
                    'Hors-ligne — données potentiellement obsolètes',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: BgColors.ink),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // ── Panneau info bas ──────────────────────────────────────────
          Positioned(
            left: 20, right: 20, bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (notStarted)
                  _InfoPanel(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'Le ramassage n\'a pas encore commencé',
                    subtitle: child?.busMatricule != null
                        ? 'Bus ${child!.busMatricule} · Départ prévu 07:00'
                        : 'Bus non assigné',
                  )
                else if (child?.status == StudentStatus.absent)
                  const _InfoPanel(
                    icon: Icons.person_off_rounded,
                    title: 'Votre enfant a été signalé absent ce matin',
                    subtitle: 'Contactez l\'école si nécessaire',
                    color: BgColors.danger,
                  )
                else if (signalLost)
                  _InfoPanel(
                    icon: Icons.gps_off_rounded,
                    title: 'Signal GPS temporairement perdu',
                    subtitle: 'Dernière position : ${pos != null ? _formatTime(pos.timestamp) : '—'}',
                    color: BgColors.danger,
                  )
                else ...[
                  EtaCard(minutes: _eta, offline: signalLost),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BgTheme.glassCard(),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: BgColors.terracotta.withValues(alpha: 0.15),
                          child: Text(
                            child?.firstName[0] ?? '?',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: BgColors.terracotta),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(child?.fullName ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                              Text(
                                'À bord · Bus ${_bus?.matricule ?? ''}',
                                style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.sage),
                              ),
                            ],
                          ),
                        ),
                        if (_bus?.trafficAlert != null)
                          const Icon(Icons.warning_rounded, color: BgColors.danger, size: 28),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = BgColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BgTheme.glassCard(),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
