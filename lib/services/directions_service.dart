import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Récupère l'itinéraire routier réel via le proxy Laravel.
/// Le backend appelle Google Directions côté serveur → aucun problème CORS.
class DirectionsService {
  static Future<List<LatLng>?> getRoute({
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

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final encoded = data['polyline'] as String?;
      if (encoded == null || encoded.isEmpty) return null;

      return _decodePolyline(encoded);
    } catch (_) {
      return null;
    }
  }

  /// Décode une Google Encoded Polyline en liste de LatLng.
  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

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
