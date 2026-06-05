import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants.dart';
import '../models/bus_model.dart';

class FirebaseService {
  static bool _initialized = false;
  static bool get isAvailable => _initialized;

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  FirebaseAuth? get _auth => _initialized ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _db => _initialized ? FirebaseFirestore.instance : null;

  Stream<BusModel?> watchBus(String busId) {
    if (!_initialized || _db == null) {
      return _demoBusStream(busId);
    }

    return _db!.collection('buses').doc(busId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final d = snap.data()!;
      final pos = d['last_position'] as Map<String, dynamic>?;
      return BusModel(
        id: busId,
        matricule: d['matricule'] as String? ?? busId,
        driverName: d['driver_name'] as String?,
        status: _statusFromString(d['status'] as String? ?? 'idle'),
        position: pos != null
            ? BusPosition(
                lat: (pos['lat'] as num).toDouble(),
                lng: (pos['lng'] as num).toDouble(),
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  (d['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
                ),
              )
            : null,
        trafficAlert: d['traffic_alert'] as String?,
      );
    });
  }

  Future<void> updateBusPosition({
    required String busId,
    required double lat,
    required double lng,
    required String driverId,
    required String driverName,
    required String matricule,
    String status = 'en_route',
  }) async {
    if (!_initialized || _db == null) return;

    await _db!.collection('buses').doc(busId).set({
      'bus_id': busId,
      'matricule': matricule,
      'driver_id': driverId,
      'driver_name': driverName,
      'status': status,
      'last_position': {'lat': lat, 'lng': lng},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> updateStudentStatus(String studentId, String status) async {
    if (!_initialized || _db == null) return;
    await _db!.collection('students').doc(studentId).set(
      {'current_status': status},
      SetOptions(merge: true),
    );
  }

  Future<void> setTrafficAlert(String busId, String? alert) async {
    if (!_initialized || _db == null) return;
    await _db!.collection('buses').doc(busId).set(
      {'traffic_alert': alert},
      SetOptions(merge: true),
    );
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (_auth == null) return null;
    return _auth!.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    if (_auth == null) return null;
    return _auth!.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async => await _auth?.signOut();

  Stream<BusModel?> _demoBusStream(String busId) async* {
    final rnd = Random(busId.hashCode);
    var lat = AppConstants.dakarLat + rnd.nextDouble() * 0.02;
    var lng = AppConstants.dakarLng + rnd.nextDouble() * 0.02;

    yield BusModel(
      id: busId,
      matricule: 'DK-1234-AB',
      driverName: 'Moussa Diop',
      status: BusStatus.enRoute,
      position: BusPosition(lat: lat, lng: lng, timestamp: DateTime.now()),
    );

    await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
      lat += (rnd.nextDouble() - 0.3) * 0.001;
      lng += (rnd.nextDouble() - 0.3) * 0.001;
      yield BusModel(
        id: busId,
        matricule: 'DK-1234-AB',
        driverName: 'Moussa Diop',
        status: BusStatus.enRoute,
        position: BusPosition(lat: lat, lng: lng, timestamp: DateTime.now()),
      );
    }
  }

  BusStatus _statusFromString(String s) => switch (s) {
        'en_route' => BusStatus.enRoute,
        'arrived' => BusStatus.arrived,
        'signal_perdu' => BusStatus.signalPerdu,
        _ => BusStatus.idle,
      };
}
