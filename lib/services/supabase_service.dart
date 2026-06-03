import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child.dart';
import '../models/bus.dart';
import '../models/alert.dart';
import '../models/profile.dart';

class SupabaseService {
  static final SupabaseClient _c = Supabase.instance.client;

  // ----- Profile -----
  static Future<Profile?> getMyProfile() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _c.from('profiles').select().eq('id', uid).maybeSingle();
    return res == null ? null : Profile.fromMap(res);
  }

  static Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final uid = _c.auth.currentUser!.id;
    await _c.from('profiles').update({
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  // ----- Children -----
  static Future<List<Child>> getMyChildren() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _c.from('children').select().eq('parent_id', uid);
    return (res as List).map((e) => Child.fromMap(e)).toList();
  }

  static Future<void> addChild(Child c) async {
    await _c.from('children').insert(c.toInsert());
  }

  static Future<void> deleteChild(String id) async {
    await _c.from('children').delete().eq('id', id);
  }

  // ----- Buses -----
  static Future<List<Bus>> getAllBuses() async {
    final res = await _c.from('buses').select();
    return (res as List).map((e) => Bus.fromMap(e)).toList();
  }

  static Future<Bus?> getBus(String id) async {
    final res = await _c.from('buses').select().eq('id', id).maybeSingle();
    return res == null ? null : Bus.fromMap(res);
  }

  // ----- Alerts -----
  static Future<List<AlertModel>> getMyAlerts() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return [];
    final res = await _c
        .from('alerts')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).map((e) => AlertModel.fromMap(e)).toList();
  }

  static Future<void> markAlertRead(String id) async {
    await _c.from('alerts').update({'read': true}).eq('id', id);
  }

  static Future<void> createAlert({
    required String type,
    required String title,
    String? message,
    String? childId,
  }) async {
    final uid = _c.auth.currentUser!.id;
    await _c.from('alerts').insert({
      'user_id': uid,
      'type': type,
      'title': title,
      if (message != null) 'message': message,
      if (childId != null) 'child_id': childId,
    });
  }
}
