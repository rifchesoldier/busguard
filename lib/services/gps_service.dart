import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';

/// Service GPS du chauffeur.
/// - Demande les permissions
/// - Émet la position toutes les [AppConstants.gpsUpdateIntervalSec] secondes
/// - Détecte la perte de signal au-delà de [AppConstants.gpsSignalLostSec] secondes
class GpsService {
  StreamSubscription<Position>? _positionSub;
  Timer? _signalWatchdog;
  Timer? _periodicEmitter;

  DateTime? _lastFix;
  Position? _lastPosition;

  bool get isTracking => _positionSub != null;

  // ── Permissions ─────────────────────────────────────────────────────────────

  /// Demande la permission GPS. Retourne true si accordée.
  Future<bool> requestPermission() async {
    // Sur le Web, geolocator utilise l'API browser — pas de permis système à demander.
    if (kIsWeb) return true;

    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      // L'utilisateur a refusé définitivement — ouvrir les paramètres
      await Geolocator.openAppSettings();
      return false;
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  // ── Démarrage du tracking ───────────────────────────────────────────────────

  /// Démarre le tracking GPS.
  ///
  /// [onPosition] est appelé à chaque nouvelle position reçue.
  /// [onSignalLost] est appelé quand aucune position n'est reçue depuis
  /// [AppConstants.gpsSignalLostSec] secondes.
  void startTracking(
    void Function(Position position) onPosition, {
    void Function()? onSignalLost,
  }) {
    stopTracking(); // nettoyer si déjà actif

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // émettre même sans déplacement
      timeLimit: null,
    );

    // Abonnement au stream de positions
    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (pos) {
        _lastFix = DateTime.now();
        _lastPosition = pos;
        onPosition(pos);
        debugPrint(
          '[GPS] Position reçue: ${pos.latitude.toStringAsFixed(5)}, '
          '${pos.longitude.toStringAsFixed(5)} '
          '(précision: ${pos.accuracy.toStringAsFixed(1)}m)',
        );
      },
      onError: (e) {
        debugPrint('[GPS] Erreur stream: $e');
        onSignalLost?.call();
      },
    );

    // Watchdog : détecte la perte de signal toutes les 5s
    _signalWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastFix == null) return;
      final elapsed = DateTime.now().difference(_lastFix!).inSeconds;
      if (elapsed > AppConstants.gpsSignalLostSec) {
        debugPrint('[GPS] Signal perdu depuis ${elapsed}s');
        onSignalLost?.call();
      }
    });

    // Émetteur périodique : force un envoi toutes les N secondes
    // même si la position n'a pas changé (pour le suivi continu)
    _periodicEmitter = Timer.periodic(
      Duration(seconds: AppConstants.gpsUpdateIntervalSec),
      (_) {
        final pos = _lastPosition;
        if (pos != null) {
          onPosition(pos);
        }
      },
    );

    debugPrint('[GPS] Tracking démarré');
  }

  // ── Arrêt du tracking ───────────────────────────────────────────────────────

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _signalWatchdog?.cancel();
    _signalWatchdog = null;
    _periodicEmitter?.cancel();
    _periodicEmitter = null;
    debugPrint('[GPS] Tracking arrêté');
  }

  // ── Getters ─────────────────────────────────────────────────────────────────

  Position? get lastPosition => _lastPosition;

  /// Obtient une position unique (pour initialisation).
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[GPS] getCurrentPosition error: $e');
      return null;
    }
  }
}
