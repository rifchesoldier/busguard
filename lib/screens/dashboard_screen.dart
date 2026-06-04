import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import '../models/bus.dart';
import '../utils/home_shell_navigator.dart'; // Import indispensable pour le HomeShellProvider

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GoogleMapController? _mapController;
  LatLng? _myPosition;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _locationSub;

  // ── Données dynamiques ──────────────────────────────────────────────────
  int _childrenCount = 0;
  int _unreadAlertsCount = 0;

  // ── ETA BUS : minuteur dynamique ────────────────────────────────────────
  int _etaSeconds = 7 * 60; // 7 minutes initiales
  Timer? _etaTimer;

  // ── PONCTUALITÉ : boucle dynamique ──────────────────────────────────────
  final List<Map<String, dynamic>> _punctualityStats = [
    {'label': 'Semaine', 'value': 98},
    {'label': 'Mois', 'value': 95},
    {'label': 'Trimestre', 'value': 92},
    {'label': "Aujourd'hui", 'value': 100},
  ];
  int _punctualityIndex = 0;
  Timer? _punctualityTimer;

  static const _dakar = LatLng(14.6937, -17.4441);

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadBusMarkers();
    _loadDashboardData();   
    _startEtaTimer();       
    _startPunctualityLoop(); 
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapController?.dispose();
    _etaTimer?.cancel();
    _punctualityTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final children = await SupabaseService.getMyChildren();
    final alerts = await SupabaseService.getMyAlerts();
    final unread = alerts.where((a) => !a.read).toList();
    if (mounted) {
      setState(() {
        _childrenCount = children.length;
        _unreadAlertsCount = unread.length;
      });
    }
  }

  void _startEtaTimer() {
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_etaSeconds > 0) {
          _etaSeconds--;
        } else {
          _etaSeconds = 10 * 60;
        }
      });
    });
  }

  String get _etaLabel {
    final m = _etaSeconds ~/ 60;
    final s = _etaSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}min ${s.toString().padLeft(2, '0')}s';
  }

  void _startPunctualityLoop() {
    _punctualityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _punctualityIndex = (_punctualityIndex + 1) % _punctualityStats.length;
      });
    });
  }

  String get _punctualityLabel =>
      '${_punctualityStats[_punctualityIndex]['value']}%';
  String get _punctualitySubtitle =>
      _punctualityStats[_punctualityIndex]['label'] as String;

  Future<void> _initLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      setState(() => _myPosition = _dakar);
      return;
    }

    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _myPosition = latLng);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 14)),
      );
      _addMyMarker(latLng);
    }

    _locationSub = LocationService.positionStream().listen((p) {
      if (!mounted) return;
      final latLng = LatLng(p.latitude, p.longitude);
      setState(() => _myPosition = latLng);
      _addMyMarker(latLng);
    });
  }

  void _addMyMarker(LatLng pos) {
    final marker = Marker(
      markerId: const MarkerId('__me__'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Ma position'),
      zIndex: 2,
    );
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == '__me__');
      _markers = {..._markers, marker};
    });
  }

  Future<void> _loadBusMarkers() async {
    final buses = await SupabaseService.getAllBuses();
    final busMarkers = <Marker>{};
    for (final Bus b in buses) {
      if (b.lat != null && b.lng != null) {
        busMarkers.add(Marker(
          markerId: MarkerId(b.id),
          position: LatLng(b.lat!, b.lng!),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: b.plate,
            snippet: '${b.routeName ?? ''} • ETA ${b.etaMinutes ?? "?"} min',
          ),
          zIndex: 1,
        ));
      }
    }
    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value != '__me__');
        _markers = {..._markers, ...busMarkers};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Bonjour 👋",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 4),
            Text(
              "Voici la situation en temps réel.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            GridView.count(
              crossAxisCount:
                  screenWidth < 600 ? 2 : (screenWidth < 1100 ? 2 : 4),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildNavigableKpiCard(
                  title: 'ENFANTS SUIVIS',
                  value: '$_childrenCount',
                  icon: Icons.people_alt_outlined,
                  targetIndex: 2,
                ),
                _buildNavigableKpiCard(
                  title: 'ALERTES NON LUES',
                  value: '$_unreadAlertsCount',
                  icon: Icons.notifications_none_outlined,
                  badgeColor: _unreadAlertsCount > 0 ? Colors.blue : null,
                  targetIndex: 3,
                ),
                _buildEtaKpiCard(),
                _buildPunctualityKpiCard(),
              ],
            ),
            const SizedBox(height: 32),

            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildLiveTrackingTile()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildDailyActivityTile()),
                    ],
                  )
                : Column(
                    children: [
                      _buildLiveTrackingTile(),
                      const SizedBox(height: 24),
                      _buildDailyActivityTile(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // ── MODIFICATION APPLIQUÉE ICI ───────────────────────────────────────────
  Widget _buildNavigableKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required int targetIndex,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: () {
        // CORRECTION : Recherche via le Provider hérité plutôt que findAncestorStateOfType
        final homeShellNavigator = HomeShellProvider.of(context);
        homeShellNavigator?.navigateTo(targetIndex);
      },
      child: _buildKpiCardContent(
        title: title,
        value: value,
        icon: icon,
        badgeColor: badgeColor,
        isClickable: true,
      ),
    );
  }

  Widget _buildEtaKpiCard() {
    return _buildKpiCardContent(
      title: 'ETA BUS',
      value: _etaLabel,
      icon: Icons.access_time,
      valueColor: _etaSeconds < 60 ? Colors.orange : const Color(0xFF1A237E),
    );
  }

  Widget _buildPunctualityKpiCard() {
    return _buildKpiCardContent(
      title: 'PONCTUALITÉ',
      value: _punctualityLabel,
      icon: Icons.trending_up,
      subtitle: _punctualitySubtitle,
      valueColor: _punctualityStats[_punctualityIndex]['value'] as int >= 90
          ? Colors.green
          : Colors.orange,
    );
  }

  Widget _buildKpiCardContent({
    required String title,
    required String value,
    required IconData icon,
    Color? badgeColor,
    Color? valueColor,
    String? subtitle,
    bool isClickable = false,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isClickable
              ? const Color(0xFF1A237E).withOpacity(0.3)
              : Colors.grey.shade200,
          width: isClickable ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: const Color(0xFF1A237E), size: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeColor != null)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: badgeColor, shape: BoxShape.circle),
                      ),
                    if (isClickable) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 10, color: Colors.grey[400]),
                    ],
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? const Color(0xFF1A237E),
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon,
      {Color? badgeColor}) {
    return _buildKpiCardContent(
        title: title, value: value, icon: icon, badgeColor: badgeColor);
  }

  Widget _buildLiveTrackingTile() {
    final initialPos =
        CameraPosition(target: _myPosition ?? _dakar, zoom: 13);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Suivi en direct",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text("EN DIRECT",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Bus DK-402-AB · Ligne B — Mermoz",
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Container(
              height: 400,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: initialPos,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController c) {
                  _mapController = c;
                  if (_myPosition != null) {
                    c.animateCamera(CameraUpdate.newCameraPosition(
                        CameraPosition(target: _myPosition!, zoom: 14)));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivityTile() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Activité du jour",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E))),
            const SizedBox(height: 20),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActivityRow("Départ confirmé",
                    "Le bus a démarré depuis l'école.", "07:15", Colors.green,
                    isFirst: true),
                _buildActivityRow("Approche : 3 arrêts",
                    "Préparez-vous à descendre.", "07:38", Colors.green),
                _buildActivityRow("Arrivée à l'arrêt",
                    "Le bus est arrêté à votre point.", "07:44", Colors.green),
                _buildActivityRow(
                    "Descente confirmée",
                    "Badge scanné. Aminata a quitté le bus.",
                    "07:45",
                    Colors.green,
                    isLast: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(
      String title, String desc, String time, Color color,
      {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                  width: 2,
                  height: 10,
                  color: isFirst ? Colors.transparent : Colors.grey.shade300),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.check, size: 12, color: color),
              ),
              Expanded(
                  child: Container(
                      width: 2,
                      color:
                          isLast ? Colors.transparent : Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A237E))),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          Text(time,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
        ],
      ),
    );
  }
}