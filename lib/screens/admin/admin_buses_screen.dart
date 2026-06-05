import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../models/school_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AdminBusesScreen extends StatefulWidget {
  const AdminBusesScreen({super.key});
  @override
  State<AdminBusesScreen> createState() => _AdminBusesScreenState();
}

class _AdminBusesScreenState extends State<AdminBusesScreen> {
  List<BusModel> _buses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthService>().api;
      _buses = await api.myBuses();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BgColors.cream,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: BgColors.terracotta,
              child: _buses.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _buses.length,
                      itemBuilder: (_, i) => _BusTile(bus: _buses[i], onDelete: _load),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        backgroundColor: BgColors.terracotta,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nouveau bus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_rounded, size: 64, color: BgColors.dusk.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucun bus enregistré', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Appuyez sur + pour en ajouter un', style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.6))),
          ],
        ),
      );

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusForm(onSaved: _load),
    );
  }
}

class _BusTile extends StatelessWidget {
  final BusModel bus;
  final VoidCallback onDelete;
  const _BusTile({required this.bus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BgTheme.glassCard(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BgColors.terracotta.withValues(alpha: 0.15),
            child: const Icon(Icons.directions_bus_rounded, color: BgColors.terracotta),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bus.matricule, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                Text('${bus.model ?? 'Modèle inconnu'} · ${bus.capacity} places',
                    style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.7))),
                if (bus.driverName != null)
                  Text('Chauffeur : ${bus.driverName}',
                      style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.sage)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: BgColors.danger),
            onPressed: () async {
              final ok = await _confirmDelete(context);
              if (ok == true && context.mounted) {
                try {
                  await context.read<AuthService>().api.deleteBus(bus.id);
                  onDelete();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: BgColors.danger),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Supprimer ce bus ?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Text('Le bus ${bus.matricule} sera supprimé.', style: GoogleFonts.dmSans()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer', style: TextStyle(color: BgColors.danger)),
            ),
          ],
        ),
      );
}

class _BusForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _BusForm({required this.onSaved});
  @override
  State<_BusForm> createState() => _BusFormState();
}

class _BusFormState extends State<_BusForm> {
  final _formKey = GlobalKey<FormState>();
  final _matricule = TextEditingController();
  final _model = TextEditingController();
  final _capacity = TextEditingController(text: '35');
  List<SchoolModel> _schools = [];
  List<UserModel> _drivers = [];
  String? _selectedSchoolId;
  String? _selectedDriverId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<AuthService>().api;
    final user = context.read<AuthService>().user;
    try {
      final schools = await api.getSchools();
      final drivers = await api.getUsers(role: 'driver');
      if (mounted) {
        setState(() {
          _schools = schools;
          _drivers = drivers;
          // Pré-sélectionner l'école de l'admin si disponible
          if (user?.schoolId != null) {
            _selectedSchoolId = user!.schoolId;
          } else if (schools.length == 1) {
            _selectedSchoolId = schools.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement : ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: BgColors.danger),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une école')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.createBus(
            schoolId: _selectedSchoolId!,
            matricule: _matricule.text.trim(),
            model: _model.text.trim().isEmpty ? null : _model.text.trim(),
            capacity: int.tryParse(_capacity.text),
            driverId: _selectedDriverId,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: BgColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: BgColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: BgColors.dusk.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Enregistrer un bus', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _matricule,
                decoration: const InputDecoration(labelText: 'Matricule *', prefixIcon: Icon(Icons.directions_bus_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _model,
                decoration: const InputDecoration(labelText: 'Modèle (ex: Toyota Coaster)', prefixIcon: Icon(Icons.commute_rounded)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacité *', prefixIcon: Icon(Icons.people_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              if (_schools.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: BgColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Aucune école disponible. Créez une école d\'abord.', style: GoogleFonts.dmSans(color: BgColors.dusk)),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedSchoolId,
                  decoration: const InputDecoration(labelText: 'École *', prefixIcon: Icon(Icons.school_rounded)),
                  items: _schools.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => _selectedSchoolId = v),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              const SizedBox(height: 14),
              if (_drivers.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  decoration: const InputDecoration(labelText: 'Chauffeur assigné', prefixIcon: Icon(Icons.person_pin_rounded)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                    ..._drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedDriverId = v),
                ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Enregistrer le bus', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
