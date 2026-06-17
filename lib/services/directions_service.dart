import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Récupère l'itinéraire routier réel.
/// Stratégie en 3 niveaux :
///   1. Proxy Laravel (backend appelle Google → pas de CORS)
///   2. Google Directions API directe via flutter_polyline_points (mobile/desktop)
///   3. Google Directions via CORS proxy (Web/Chrome uniquement)
class DirectionsService {

  static Future<List<LatLng>?> getRoute({
    required LatLng origin,
    required LatLng destination,
    required String token,
  }) async {
    // 1️⃣ Proxy Laravel
    final fromProxy = await _getRouteFromProxy(
      origin: origin,
      destination: destination,
      token: token,
    );
    if (fromProxy != null && fromProxy.length > 2) {
      debugPrint('[Directions] ✅ Route via proxy Laravel (${fromProxy.length} points)');
      return fromProxy;
    }
    debugPrint('[Directions] ⚠️ Proxy échoué, fallback Google direct');

    // 2️⃣ Fallback : appel HTTP direct à Google Directions (fonctionne partout)
    final fromGoogle = await _getRouteFromGoogleHttp(
      origin: origin,
      destination: destination,
    );
    if (fromGoogle != null && fromGoogle.length > 2) {
      debugPrint('[Directions] ✅ Route via Google HTTP direct (${fromGoogle.length} points)');
      return fromGoogle;
    }
    debugPrint('[Directions] ⚠️ Google HTTP direct échoué, essai flutter_polyline_points');

    // 3️⃣ Fallback : flutter_polyline_points (mobile/desktop)
    if (!kIsWeb) {
      final fromLib = await _getRouteFromPolylineLib(
        origin: origin,
        destination: destination,
      );
      if (fromLib != null && fromLib.length > 2) {
        debugPrint('[Directions] ✅ Route via flutter_polyline_points (${fromLib.length} points)');
        return fromLib;
      }
    }

    debugPrint('[Directions] ❌ Tous les services ont échoué — vérifier la clé API ou la connexion');
    return null;
  }

  // ---------------------------------------------------------------------------
  // 1. Proxy Laravel
  // ---------------------------------------------------------------------------
  static Future<List<LatLng>?> _getRouteFromProxy({
    required LatLng origin,
    required LatLng destination,
    required String token,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/directions/route/points',
      ).replace(queryParameters: {
        'origin_lat': origin.latitude.toString(),
        'origin_lng': origin.longitude.toString(),
        'dest_lat': destination.latitude.toString(),
        'dest_lng': destination.longitude.toString(),
      });

      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      debugPrint('[Directions] Proxy status: ${res.statusCode}');
      if (res.statusCode != 200) {
        debugPrint('[Directions] Proxy body: ${res.body}');
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final encoded = data['polyline'] as String?;
      if (encoded == null || encoded.isEmpty) return null;

      final points = _decodePolyline(encoded);
      return points.length > 2 ? points : null;
    } catch (e) {
      debugPrint('[Directions] Proxy exception: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Google Directions API — appel HTTP direct
  // ---------------------------------------------------------------------------
  static Future<List<LatLng>?> _getRouteFromGoogleHttp({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final key = AppConstants.googleMapsApiKey;
      if (key.isEmpty) {
        debugPrint('[Directions] Clé Google Maps non configurée');
        return null;
      }

      final uri = Uri.parse('https://maps.googleapis.com/maps/api/directions/json').replace(
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'key': key,
          'language': 'fr',
          'region': 'SN',
        },
      );

      debugPrint('[Directions] Appel Google Directions: $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('[Directions] Google status: ${res.statusCode}');

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('[Directions] Google status field: ${data['status']}');

      if (data['status'] != 'OK') {
        debugPrint('[Directions] Google error: ${data['error_message'] ?? data['status']}');
        return null;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final overviewPolyline = routes[0]['overview_polyline']['points'] as String?;
      if (overviewPolyline == null || overviewPolyline.isEmpty) return null;

      return _decodePolyline(overviewPolyline);
    } catch (e) {
      debugPrint('[Directions] Google HTTP exception: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. flutter_polyline_points (mobile/desktop uniquement)
  // ---------------------------------------------------------------------------
  static Future<List<LatLng>?> _getRouteFromPolylineLib({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: AppConstants.googleMapsApiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );
      if (result.points.isNotEmpty) {
        return result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      }
      debugPrint('[Directions] flutter_polyline_points error: ${result.errorMessage}');
      return null;
    } catch (e) {
      debugPrint('[Directions] flutter_polyline_points exception: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Décodeur Google Encoded Polyline → List<LatLng>
  // ---------------------------------------------------------------------------
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}