import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/supabase_service.dart';
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

  static const _initial = CameraPosition(
    target: LatLng(5.3600, -4.0083), // Abidjan
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    final buses = await SupabaseService.getAllBuses();
    final markers = <Marker>{};
    for (final Bus b in buses) {
      if (b.lat != null && b.lng != null) {
        markers.add(Marker(
          markerId: MarkerId(b.id),
          position: LatLng(b.lat!, b.lng!),
          infoWindow: InfoWindow(
              title: b.plate,
              snippet:
                  '${b.routeName ?? ''} • ETA ${b.etaMinutes ?? "?"} min'),
        ));
      }
    }
    if (mounted) {
      setState(() {
        _markers = markers;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte en direct'),
        actions: [
          IconButton(
              onPressed: _loadBuses, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initial,
            markers: _markers,
            myLocationEnabled: true,
            onMapCreated: (c) => _controller = c,
          ),
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.navy)),
        ],
      ),
    );
  }
}
