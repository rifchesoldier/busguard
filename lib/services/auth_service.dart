import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'firebase_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FirebaseService _firebase = FirebaseService();

  UserModel? _user;
  List<StudentModel> _children = [];
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  List<StudentModel> get children => _children;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  ApiService get api => _api;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _api.setToken(token);
      try {
        _user = await _api.me();
        _children = await _api.myChildren();
        notifyListeners();
      } catch (_) {
        await prefs.remove('auth_token');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      if (FirebaseService.isAvailable) {
        await _firebase.signInWithEmail(email, password);
      }
      final data = await _api.login(email, password);
      await _persistSession(data);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required bool privacyConsent,
  }) async {
    _setLoading(true);
    try {
      String? firebaseUid;
      if (FirebaseService.isAvailable) {
        final cred = await _firebase.registerWithEmail(email, password);
        firebaseUid = cred?.user?.uid;
      }
      final data = await _api.registerParent(
        name: name,
        email: email,
        password: password,
        phone: phone,
        privacyConsent: privacyConsent,
        firebaseUid: firebaseUid,
      );
      await _persistSession(data);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshChildren() async {
    _children = await _api.myChildren();
    notifyListeners();
  }

  Future<void> logout() async {
    await _firebase.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _user = null;
    _children = [];
    _api.setToken(null);
    notifyListeners();
  }

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    _api.setToken(token);
    _user = UserModel.fromJson(data['user'] as Map<String, dynamic>, token: token);
    _children = await _api.myChildren();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    _error = null;
    notifyListeners();
  }
}
