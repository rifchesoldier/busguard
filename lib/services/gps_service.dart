import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';

class GpsService {
  StreamSubscription<Position>? _subscription;
  DateTime? _lastUpdate;
  Position? _lastPosition;

  Future<bool> requestPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  void startTracking(void Function(Position) onPosition, {void Function()? onSignalLost}) {
    _subscription?.cancel();
    _subscription = positionStream().listen((pos) {
      _lastUpdate = DateTime.now();
      _lastPosition = pos;
      onPosition(pos);
    });

    Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastUpdate != null &&
          DateTime.now().difference(_lastUpdate!).inSeconds > AppConstants.gpsSignalLostSec) {
        onSignalLost?.call();
      }
    });
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
  }

  Position? get lastPosition => _lastPosition;
}
