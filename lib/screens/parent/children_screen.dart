import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/school_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/child_tile.dart';

class ParentChildrenScreen extends StatelessWidget {
  const ParentChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes enfants')),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshChildren(),
        color: BgColors.terracotta,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Bannière info
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [BgColors.sage.withValues(alpha: 0.2), BgColors.gold.withValues(alpha: 0.15)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: BgColors.sage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Inscrivez vos enfants ici. L\'affectation au bus sera confirmée par l\'administrateur scolaire.',
                      style: GoogleFonts.dmSans(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            if (auth.children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.child_care_rounded, size: 64, color: BgColors.dusk.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Aucun enfant enregistré', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Appuyez sur le bouton + pour inscrire votre enfant',
                        style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.6)),
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              ...auth.children.map((c) => ChildTile(child: c)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterForm(context),
        backgroundColor: BgColors.terracotta,
        icon: const Icon(Icons.child_care_rounded, color: Colors.white),
        label: Text('Inscrire un enfant', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showRegisterForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegisterChildForm(
        onSaved: () => context.read<AuthService>().refreshChildren(),
      ),
    );
  }
}

// ── Formulaire inscription enfant (parent) ────────────────────────────────────

class _RegisterChildForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _RegisterChildForm({required this.onSaved});
  @override
  State<_RegisterChildForm> createState() => _RegisterChildFormState();
}

class _RegisterChildFormState extends State<_RegisterChildForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  List<SchoolModel> _schools = [];
  SchoolModel? _selectedSchool;
  String? _selectedClass;
  bool _saving = false;
  bool _loadingSchools = true;
  String? _schoolError;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() { _loadingSchools = true; _schoolError = null; });
    try {
      final schools = await context.read<AuthService>().api.getSchools();
      if (mounted) setState(() { _schools = schools; _loadingSchools = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loadingSchools = false;
        _schoolError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une école')));
      return;
    }
    setState(() => _saving = true);
    try {
      final parentId = context.read<AuthService>().user!.id;
      await context.read<AuthService>().api.createStudent(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            schoolId: _selectedSchool!.id,
            className: _selectedClass,
            parentId: parentId,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_firstName.text} inscrit(e) avec succès ! L\'admin assignera un bus.'),
            backgroundColor: BgColors.success,
          ),
        );
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
    final classes = _selectedSchool?.availableClasses ?? [];

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
              Text('Inscrire mon enfant', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
              Text('Renseignez les informations de votre enfant.', style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk.withValues(alpha: 0.6))),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'Prénom *', prefixIcon: Icon(Icons.person_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Nom *', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              if (_loadingSchools)
                const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
              else if (_schoolError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: BgColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: BgColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Erreur : $_schoolError', style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.danger))),
                      TextButton(onPressed: _loadSchools, child: const Text('Réessayer')),
                    ],
                  ),
                )
              else if (_schools.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: BgColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Aucune école disponible pour le moment.', style: GoogleFonts.dmSans()),
                )
              else
                DropdownButtonFormField<SchoolModel>(
                  value: _selectedSchool,
                  decoration: const InputDecoration(labelText: 'École *', prefixIcon: Icon(Icons.school_rounded)),
                  items: _schools.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (s) => setState(() { _selectedSchool = s; _selectedClass = null; }),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              const SizedBox(height: 14),
              if (_selectedSchool != null)
                if (classes.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(labelText: 'Classe', prefixIcon: Icon(Icons.class_rounded)),
                    items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedClass = v),
                  )
                else
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Classe (ex : CM2 A)', prefixIcon: Icon(Icons.class_rounded)),
                    onChanged: (v) => _selectedClass = v,
                  ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Inscrire mon enfant', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
