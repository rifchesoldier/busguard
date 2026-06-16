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
  bool _routeLoading = false;

  LatLng? _schoolLatLng;
  static const _dakarLatLng = LatLng(AppConstants.dakarLat, AppConstants.dakarLng);

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
    if (auth.children.isEmpty) return;

    try {
      _child = auth.children.firstWhere((c) => c.busId != null);
    } catch (_) {
      _child = auth.children.first;
    }

    if (_child == null) return;

    if (_child!.schoolLat != null && _child!.schoolLng != null) {
      _schoolLatLng = LatLng(_child!.schoolLat!, _child!.schoolLng!);
      // Marqueur école immédiat
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('school'),
            position: _schoolLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: _child?.schoolName ?? 'École', snippet: 'Destination'),
          ),
        };
      });
    }

    if (_child!.busId == null) return;

    _busSub = _firebase.watchBus(_child!.busId!).listen((bus) {
      if (!mounted || bus?.position == null) return;
      setState(() => _bus = bus);
      _updateMapOverlays(bus!);
    });

    _etaTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_child?.busId != null) _refreshEta(_child!.busId!);
    });
    _refreshEta(_child!.busId!);
  }

  Future<void> _updateMapOverlays(BusModel bus) async {
    final busPos = LatLng(bus.position!.lat, bus.position!.lng);
    final destination = _schoolLatLng ?? _dakarLatLng;

    final newMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('bus'),
        position: busPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          bus.trafficAlert != null ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(title: 'Bus ${bus.matricule}', snippet: bus.statusLabel),
        zIndex: 2,
      ),
      Marker(
        markerId: const MarkerId('school'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: _child?.schoolName ?? 'École', snippet: 'Destination'),
        zIndex: 1,
      ),
    };

    if (mounted) setState(() { _routeLoading = true; _markers = newMarkers; });

    // Trajet routier : proxy Laravel en priorité, sinon Google Directions direct
    List<LatLng> polylinePoints = [];
    bool routeFailed = false;
    try {
      final token = context.read<AuthService>().user?.token;
      if (token != null) {
        final route = await DirectionsService.getRoute(
          origin: busPos,
          destination: destination,
          token: token,
        );
        if (route != null && route.length > 2) {
          polylinePoints = route;
        } else {
          routeFailed = true;
        }
      } else {
        routeFailed = true;
      }
    } catch (_) {
      routeFailed = true;
    }

    // Si les deux services ont échoué, on trace une ligne droite en pointillés
    // pour indiquer que le trajet réel n'a pas pu être chargé
    if (routeFailed || polylinePoints.length <= 2) {
      polylinePoints = [busPos, destination];
    }

    if (!mounted) return;

    // Cadrage automatique
    try {
      final bounds = _boundsFromPoints([busPos, destination, ...polylinePoints]);
      await _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (_) {}

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: routeFailed ? BgColors.dusk.withValues(alpha: 0.5) : BgColors.terracotta,
            width: routeFailed ? 3 : 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            geodesic: true,
            patterns: routeFailed
                ? [PatternItem.dash(20), PatternItem.gap(10)]
                : [],
          ),
        };
        _routeLoading = false;
      });
    }
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
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
    final initialTarget = _schoolLatLng ?? _dakarLatLng;

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          GoogleMap(
            onMapCreated: (c) {
              _mapController = c;
              if (_schoolLatLng != null) {
                c.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: _schoolLatLng!, zoom: 14),
                ));
              }
            },
            initialCameraPosition: CameraPosition(target: initialTarget, zoom: 13),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            padding: const EdgeInsets.only(bottom: 180),
          ),

          // ── Indicateur calcul itinéraire ──────────────────────────────
          if (_routeLoading)
            Positioned(
              top: 60, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: BgColors.ink.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text('Calcul de l\'itinéraire…',
                          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bannière hors-ligne ──────────────────────────────────────
          if (_offline)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Material(
                color: BgColors.gold,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Text('Hors-ligne — données potentiellement obsolètes',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: BgColors.ink),
                      textAlign: TextAlign.center),
                ),
              ),
            ),

          // ── Panneau info bas ─────────────────────────────────────────
          Positioned(
            left: 20, right: 20, bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (child == null)
                  const _InfoPanel(icon: Icons.child_care_rounded, title: 'Aucun enfant enregistré', subtitle: 'Inscrivez votre enfant dans l\'onglet Enfants')
                else if (child.busId == null)
                  _InfoPanel(icon: Icons.directions_bus_outlined, title: 'Bus non encore assigné', subtitle: '${child.firstName} attend une affectation par l\'administrateur')
                else if (notStarted)
                  _InfoPanel(icon: Icons.hourglass_empty_rounded, title: 'Le ramassage n\'a pas encore commencé', subtitle: 'Bus ${child.busMatricule ?? child.busId} · Départ prévu 07:00')
                else if (child.status == StudentStatus.absent)
                  const _InfoPanel(icon: Icons.person_off_rounded, title: 'Votre enfant a été signalé absent ce matin', subtitle: 'Contactez l\'école si nécessaire', color: BgColors.danger)
                else if (signalLost)
                  _InfoPanel(icon: Icons.gps_off_rounded, title: 'Signal GPS temporairement perdu', subtitle: 'Dernière position : ${pos != null ? _formatTime(pos.timestamp) : '—'}', color: BgColors.danger)
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
                          child: Text(child.firstName[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: BgColors.terracotta)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(child.fullName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                              Text('À bord · Bus ${_bus?.matricule ?? ''}', style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.sage)),
                              if (child.schoolName != null)
                                Text('→ ${child.schoolName}', style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.6))),
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

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _InfoPanel({required this.icon, required this.title, required this.subtitle, this.color = BgColors.ink});

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
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
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