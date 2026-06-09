import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/school_model.dart';
import '../../services/auth_service.dart';

class AdminSchoolsScreen extends StatefulWidget {
  const AdminSchoolsScreen({super.key});
  @override
  State<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends State<AdminSchoolsScreen> {
  List<SchoolModel> _schools = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _schools = await context.read<AuthService>().api.getSchools();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BgColors.cream,
      appBar: AppBar(
        title: const Text('Gestion des écoles'),
        backgroundColor: BgColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF2D4A7A),
              child: _schools.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _schools.length,
                      itemBuilder: (_, i) => _SchoolTile(school: _schools[i], onDelete: _load),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        backgroundColor: const Color(0xFF2D4A7A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nouvelle école', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 64, color: BgColors.dusk.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucune école enregistrée', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SchoolForm(onSaved: _load),
    );
  }
}

class _SchoolTile extends StatelessWidget {
  final SchoolModel school;
  final VoidCallback onDelete;
  const _SchoolTile({required this.school, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BgTheme.glassCard(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2D4A7A).withValues(alpha: 0.12),
            child: const Icon(Icons.school_rounded, color: Color(0xFF2D4A7A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(school.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${school.city}${school.address != null ? ' · ${school.address}' : ''}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  school.availableClasses.isNotEmpty
                      ? 'Classes : ${school.availableClasses.join(', ')}'
                      : 'Classes : non renseignées',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: school.availableClasses.isNotEmpty
                        ? BgColors.sage
                        : BgColors.dusk.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: BgColors.danger),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Supprimer cette école ?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer', style: TextStyle(color: BgColors.danger))),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                try {
                  await context.read<AuthService>().api.deleteSchool(school.id);
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
}

class _SchoolForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _SchoolForm({required this.onSaved});
  @override
  State<_SchoolForm> createState() => _SchoolFormState();
}

class _SchoolFormState extends State<_SchoolForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController(text: 'Dakar');
  final _address = TextEditingController();
  final _classesCtrl = TextEditingController(text: 'CP,CE1,CE2,CM1,CM2');
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.createSchool(
            name: _name.text.trim(),
            city: _city.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
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
      decoration: const BoxDecoration(color: BgColors.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: BgColors.dusk.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Enregistrer une école', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom de l\'école *', prefixIcon: Icon(Icons.school_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Ville *', prefixIcon: Icon(Icons.location_city_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.map_rounded)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _classesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Classes disponibles (séparées par virgule)',
                  prefixIcon: Icon(Icons.class_rounded),
                  hintText: 'CP,CE1,CE2,CM1,CM2',
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D4A7A)),
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Enregistrer l\'école', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
