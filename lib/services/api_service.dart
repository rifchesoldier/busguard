import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/bus_model.dart';
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

  Future<List<BusModel>> myBuses() async {
    final res = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/buses'),
      headers: _headers,
    );
    _throwIfError(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => BusModel.fromJson(e as Map<String, dynamic>)).toList();
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
