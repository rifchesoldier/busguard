import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/bus_model.dart';
import '../models/school_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';

class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerParent({
    required String name,
    required String email,
    required String password,
    String? phone,
    bool privacyConsent = true,
    String? firebaseUid,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/register-parent'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'privacy_consent': privacyConsent,
        'firebase_uid': firebaseUid,
      }),
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<UserModel> me() async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/me'),
      headers: _headers,
    );
    _throwIfError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return UserModel.fromJson(data, token: _token);
  }

  // ── Students ──────────────────────────────────────────────────────────────

  Future<List<StudentModel>> myChildren() async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/students/parent/mine'),
      headers: _headers,
    );
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StudentModel>> getStudentsForBus(String busId) async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/buses/$busId'),
      headers: _headers,
    );
    _throwIfError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = data['students'] as List? ?? [];
    return list.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StudentModel>> getAllStudents() async {    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/students'),
      headers: _headers,
    );
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => StudentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StudentModel> createStudent({
    required String firstName,
    required String lastName,
    required String schoolId,
    String? className,
    String? parentId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/students'),
      headers: _headers,
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'school_id': schoolId,
        if (className != null) 'class_name': className,
        if (parentId != null) 'parent_id': parentId,
      }),
    );
    _throwIfError(res);
    return StudentModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<StudentModel> assignStudentToBus({
    required String studentId,
    required String busId,
    String? stopId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/students/$studentId/assign-bus'),
      headers: _headers,
      body: jsonEncode({
        'assigned_bus_id': busId,
        if (stopId != null) 'assigned_stop_id': stopId,
      }),
    );
    _throwIfError(res);
    return StudentModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getStopsForBus(String busId) async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/buses/$busId'),
      headers: _headers,
    );
    _throwIfError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = data['routes'] as List? ?? [];
    final stops = <Map<String, dynamic>>[];
    for (final r in routes) {
      final s = (r as Map<String, dynamic>)['stops'] as List? ?? [];
      stops.addAll(s.cast<Map<String, dynamic>>());
    }
    return stops;
  }

  // ── Buses ─────────────────────────────────────────────────────────────────

  Future<List<BusModel>> myBuses() async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/buses'),
      headers: _headers,
    );
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => BusModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getRoutesForBus(String busId) async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/buses/$busId'),
      headers: _headers,
    );
    _throwIfError(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = data['routes'] as List? ?? [];
    return routes.cast<Map<String, dynamic>>();
  }

  Future<void> deleteRoute(String routeId) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/routes/$routeId'),
      headers: _headers,
    );
    _throwIfError(res);
  }

  Future<void> createRoute({
    required String busId,
    required String schoolId,
    required String name,
    required String direction,
    String? scheduledStart,
    required List<Map<String, dynamic>> stops,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/routes'),
      headers: _headers,
      body: jsonEncode({
        'bus_id': busId,
        'school_id': schoolId,
        'name': name,
        'direction': direction,
        if (scheduledStart != null) 'scheduled_start': scheduledStart,
        'stops': stops,
      }),
    );
    _throwIfError(res);
  }

  Future<BusModel> createBus({
    required String schoolId,
    required String matricule,
    String? model,
    int? capacity,
    String? driverId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/buses'),
      headers: _headers,
      body: jsonEncode({
        'school_id': schoolId,
        'matricule': matricule,
        if (model != null) 'model': model,
        if (capacity != null) 'capacity': capacity,
        if (driverId != null) 'driver_id': driverId,
      }),
    );
    _throwIfError(res);
    return BusModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Envoie la position GPS du chauffeur au backend Laravel.
  /// Endpoint léger dédié — plus rapide que `updateBus()` générique.
  Future<void> pushDriverPosition({
    required String busId,
    required double lat,
    required double lng,
    String status = 'en_route',
  }) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/buses/$busId/position'),
        headers: _headers,
        body: jsonEncode({'lat': lat, 'lng': lng, 'status': status}),
      ).timeout(const Duration(seconds: 5));
      // On ignore les erreurs réseau transitoires pour ne pas bloquer le GPS
    } catch (_) {}
  }

  Future<void> deleteBus(String busId) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/buses/$busId'),
      headers: _headers,
    );
    _throwIfError(res);
  }

  Future<BusModel> updateBus({
    required String busId,
    String? model,
    int? capacity,
    String? driverId,
  }) async {
    final res = await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}/buses/$busId'),
      headers: _headers,
      body: jsonEncode({
        if (model != null) 'model': model,
        if (capacity != null) 'capacity': capacity,
        'driver_id': driverId,
      }),
    );
    _throwIfError(res);
    return BusModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Schools ───────────────────────────────────────────────────────────────

  Future<List<SchoolModel>> getSchools() async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/schools'),
      headers: _headers,
    );
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => SchoolModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SchoolModel> createSchool({
    required String name,
    String city = 'Dakar',
    String? address,
    double? lat,
    double? lng,
    String? adminId,
    List<String>? availableClasses,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/schools'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'city': city,
        if (address != null) 'address': address,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (adminId != null) 'admin_id': adminId,
        if (availableClasses != null) 'available_classes': availableClasses,
      }),
    );
    _throwIfError(res);
    return SchoolModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<SchoolModel> updateSchool({
    required String schoolId,
    String? name,
    String? city,
    String? address,
    List<String>? availableClasses,
  }) async {
    final res = await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}/schools/$schoolId'),
      headers: _headers,
      body: jsonEncode({
        if (name != null) 'name': name,
        if (city != null) 'city': city,
        'address': address,
        if (availableClasses != null) 'available_classes': availableClasses,
      }),
    );
    _throwIfError(res);
    return SchoolModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteSchool(String schoolId) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/schools/$schoolId'),
      headers: _headers,
    );
    _throwIfError(res);
  }

  // ── Users (chauffeurs / admins) ───────────────────────────────────────────

  Future<List<UserModel>> getUsers({String? role}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/users')
        .replace(queryParameters: role != null ? {'role': role} : null);
    final res = await http.get(uri, headers: _headers);
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? schoolId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/users'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
        if (schoolId != null) 'school_id': schoolId,
      }),
    );
    _throwIfError(res);
    return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteUser(String userId) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/users/$userId'),
      headers: _headers,
    );
    _throwIfError(res);
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/stats'),
      headers: _headers,
    );
    _throwIfError(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<int?> fetchEta(String busId) async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/eta/$busId'),
      headers: _headers,
    );
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['eta_minutes'] as int?;
  }

  Future<void> recordAttendance({
    required String studentId,
    required String busId,
    required String status,
    String? stopId,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/attendance'),
      headers: _headers,
      body: jsonEncode({
        'student_id': studentId,
        'bus_id': busId,
        'stop_id': stopId,
        'status': status,
      }),
    );
    _throwIfError(res);
  }

  Future<void> reportTraffic({
    required String busId,
    required String type,
    bool resolved = false,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/notifications/traffic'),
      headers: _headers,
      body: jsonEncode({'bus_id': busId, 'type': type, 'resolved': resolved}),
    );
    _throwIfError(res);
  }

  Future<void> updateFcmToken(String token) async {
    await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}/auth/fcm-token'),
      headers: _headers,
      body: jsonEncode({'fcm_token': token}),
    );
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Erreur API (${res.statusCode})');
    }
  }
}
