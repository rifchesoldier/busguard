import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../models/profile.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SupabaseService.getMyProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _name.text = p?.fullName ?? '';
      _phone.text = p?.phone ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    await SupabaseService.updateProfile(
        fullName: _name.text, phone: _phone.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil mis à jour')),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthService>().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.navy,
                    child: Text(
                      (_profile?.fullName ?? user?.email ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                    child: Text(user?.email ?? '',
                        style:
                            const TextStyle(color: AppColors.textSecondary))),
                const SizedBox(height: 32),
                TextField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Nom complet')),
                const SizedBox(height: 16),
                TextField(
                    controller: _phone,
                    decoration:
                        const InputDecoration(labelText: 'Téléphone')),
                const SizedBox(height: 24),
                ElevatedButton(
                    onPressed: _save, child: const Text('Enregistrer')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
    );
  }
}
