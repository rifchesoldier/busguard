import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../models/bus.dart';
import '../utils/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  bool _loading = true;
  bool _locationReady = false;
  LatLng? _myPosition;
  StreamSubscription<Position>? _locationSub;

  // Position par défaut (Dakar) — utilisée uniquement si le GPS échoue
  static const _defaultPosition = LatLng(14.6937, -17.4441);

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadBuses();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  /// 1. Demande la permission, obtient la position initiale,
  ///    puis lance un stream pour suivre les déplacements en temps réel.
  Future<void> _initLocation() async {
    // Vérifie / demande la permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      // Pas de permission → on reste sur la position par défaut
      if (mounted) {
        setState(() {
          _myPosition = _defaultPosition;
          _locationReady = true;
          _loading = false;
        });
      }
      return;
    }

    // Obtient la position initiale
    final Position? pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _myPosition = latLng;
        _locationReady = true;
      });
      // Centre la carte sur la position réelle
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 14),
        ),
      );
    }

    // Lance le suivi en temps réel
    _locationSub = LocationService.positionStream().listen((Position pos) {
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _myPosition = latLng);

      // Met à jour le marker "Ma position"
      _updateMyMarker(latLng);
    });
  }

  /// Ajoute / met à jour le marker bleu "Ma position" sur la carte
  void _updateMyMarker(LatLng pos) {
    final myMarker = Marker(
      markerId: const MarkerId('__my_location__'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Ma position'),
      zIndex: 2,
    );

    setState(() {
      // Supprime l'ancien marker de position s'il existe
      _markers.removeWhere((m) => m.markerId.value == '__my_location__');
      _markers = {..._markers, myMarker};
    });
  }

  /// Charge les bus depuis Supabase et les affiche comme markers rouges
  Future<void> _loadBuses() async {
    final buses = await SupabaseService.getAllBuses();
    final busMarkers = <Marker>{};

    for (final Bus b in buses) {
      if (b.lat != null && b.lng != null) {
        busMarkers.add(Marker(
          markerId: MarkerId(b.id),
          position: LatLng(b.lat!, b.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
        // Garde le marker "ma position" s'il existe déjà
        _markers.removeWhere((m) => m.markerId.value != '__my_location__');
        _markers = {..._markers, ...busMarkers};
        _loading = false;
      });
    }
  }

  /// Recentre la caméra sur la position actuelle
  void _goToMyLocation() {
    if (_myPosition == null) return;
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _myPosition!, zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Position initiale de la caméra
    final initialPosition = CameraPosition(
      target: _myPosition ?? _defaultPosition,
      zoom: 13,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte en direct'),
        actions: [
          IconButton(
            onPressed: _loadBuses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir les bus',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            markers: _markers,
            // Active le calque natif "ma position" (point bleu Google)
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // On utilise notre propre bouton
            onMapCreated: (GoogleMapController c) {
              _controller = c;
              // Si la position est déjà connue au moment où la carte est prête
              if (_locationReady && _myPosition != null) {
                c.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _myPosition!, zoom: 14),
                  ),
                );
              }
            },
          ),

          // Indicateur de chargement
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),

          // Légende
          Positioned(
            top: 12,
            left: 12,
            child: _Legend(),
          ),
        ],
      ),

      // Bouton flottant pour recentrer sur ma position
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        backgroundColor: AppColors.navy,
        tooltip: 'Ma position',
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}

/// Petite légende pour distinguer les markers
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: Colors.red, label: 'Bus scolaire'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.blue, label: 'Ma position'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_pin, color: color, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
