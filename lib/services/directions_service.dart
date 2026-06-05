import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Récupère l'itinéraire réel via le backend Laravel (proxy Google Directions).
/// Le backend appelle Google côté serveur → pas de problème CORS.
class DirectionsService {
  /// Retourne les points décodés de la polyline ou null en cas d'échec.
  static Future<List<LatLng>?> getRouteForBus({
    required String busId,
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/directions/$busId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final encoded = data['polyline'] as String?;
      if (encoded == null) return null;

      return _decodePolyline(encoded);
    } catch (_) {
      return null;
    }
  }

  /// Décode une polyline encodée Google en liste de LatLng.
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
