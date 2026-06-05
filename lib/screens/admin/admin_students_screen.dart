import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../models/school_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});
  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  List<StudentModel> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _students = await context.read<AuthService>().api.getAllStudents();
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
              color: BgColors.sage,
              child: _students.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _students.length,
                      itemBuilder: (_, i) => _StudentTile(student: _students[i], onRefresh: _load),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignDialog(context),
        backgroundColor: BgColors.sage,
        icon: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white),
        label: Text('Affecter à un bus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_care_rounded, size: 64, color: BgColors.dusk.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Aucun élève inscrit', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Les parents inscrivent leurs enfants depuis leur compte.',
                style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.6)),
                textAlign: TextAlign.center),
          ],
        ),
      );

  void _showAssignDialog(BuildContext context) {
    // Ouvre la liste pour choisir un élève sans bus puis l'affecter
    final unassigned = _students.where((s) => s.busId == null).toList();
    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les élèves ont déjà un bus assigné.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickStudentSheet(students: unassigned, onSaved: _load),
    );
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentForm(onSaved: _load),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onRefresh;
  const _StudentTile({required this.student, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final hasBus = student.busId != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BgTheme.glassCard(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BgColors.sage.withValues(alpha: 0.15),
            child: Text('${student.firstName[0]}${student.lastName[0]}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: BgColors.sage, fontSize: 13)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                Text('${student.schoolName ?? 'École'} · ${student.className ?? '—'}',
                    style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.7))),
                Row(
                  children: [
                    Icon(
                      hasBus ? Icons.directions_bus_rounded : Icons.warning_amber_rounded,
                      size: 14,
                      color: hasBus ? BgColors.success : BgColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasBus ? 'Bus ${student.busMatricule ?? student.busId}' : 'Pas de bus assigné',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: hasBus ? BgColors.success : BgColors.gold,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!hasBus)
            TextButton(
              onPressed: () => _showAssignBus(context, student),
              style: TextButton.styleFrom(foregroundColor: BgColors.terracotta),
              child: Text('Assigner', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  void _showAssignBus(BuildContext context, StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignBusForm(student: student, onSaved: onRefresh),
    );
  }
}

// ── Feuille de sélection d'élève à affecter ───────────────────────────────────

class _PickStudentSheet extends StatelessWidget {
  final List<StudentModel> students;
  final VoidCallback onSaved;
  const _PickStudentSheet({required this.students, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: BgColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: BgColors.dusk.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Choisir un élève à affecter',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
          Text('Élèves sans bus assigné',
              style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk.withValues(alpha: 0.6))),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: CircleAvatar(
                    backgroundColor: BgColors.sage.withValues(alpha: 0.15),
                    child: Text('${s.firstName[0]}${s.lastName[0]}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: BgColors.sage, fontSize: 13)),
                  ),
                  title: Text(s.fullName, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  subtitle: Text('${s.schoolName ?? ''} · ${s.className ?? '—'}',
                      style: GoogleFonts.dmSans(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: BgColors.terracotta),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _AssignBusForm(student: s, onSaved: onSaved),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formulaire inscription élève (gardé pour usage interne) ───────────────────

class _StudentForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _StudentForm({required this.onSaved});
  @override
  State<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  List<SchoolModel> _schools = [];
  List<UserModel> _parents = [];
  SchoolModel? _selectedSchool;
  String? _selectedClass;
  String? _selectedParentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = context.read<AuthService>().api;
    try {
      final schools = await api.getSchools();
      final parents = await api.getUsers(role: 'parent');
      if (mounted) setState(() { _schools = schools; _parents = parents; });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une école')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.createStudent(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            schoolId: _selectedSchool!.id,
            className: _selectedClass,
            parentId: _selectedParentId,
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
              Text('Inscrire un élève', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
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
              if (_schools.isNotEmpty)
                DropdownButtonFormField<SchoolModel>(
                  value: _selectedSchool,
                  decoration: const InputDecoration(labelText: 'École *', prefixIcon: Icon(Icons.school_rounded)),
                  items: _schools.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (s) => setState(() { _selectedSchool = s; _selectedClass = null; }),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
              const SizedBox(height: 14),
              if (classes.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: const InputDecoration(labelText: 'Classe', prefixIcon: Icon(Icons.class_rounded)),
                  items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedClass = v),
                )
              else
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Classe (ex: CM2 A)', prefixIcon: Icon(Icons.class_rounded)),
                  onChanged: (v) => _selectedClass = v,
                ),
              const SizedBox(height: 14),
              if (_parents.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedParentId,
                  decoration: const InputDecoration(labelText: 'Parent (optionnel)', prefixIcon: Icon(Icons.family_restroom_rounded)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                    ..._parents.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.email})'))),
                  ],
                  onChanged: (v) => setState(() => _selectedParentId = v),
                ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: BgColors.sage),
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Inscrire l\'élève', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Formulaire affectation bus ─────────────────────────────────────────────────

class _AssignBusForm extends StatefulWidget {
  final StudentModel student;
  final VoidCallback onSaved;
  const _AssignBusForm({required this.student, required this.onSaved});
  @override
  State<_AssignBusForm> createState() => _AssignBusFormState();
}

class _AssignBusFormState extends State<_AssignBusForm> {
  List<BusModel> _buses = [];
  List<Map<String, dynamic>> _stops = [];
  String? _selectedBusId;
  String? _selectedStopId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    try {
      final buses = await context.read<AuthService>().api.myBuses();
      if (mounted) setState(() => _buses = buses);
    } catch (_) {}
  }

  Future<void> _loadStops(String busId) async {
    setState(() { _stops = []; _selectedStopId = null; });
    try {
      final stops = await context.read<AuthService>().api.getStopsForBus(busId);
      if (mounted) setState(() => _stops = stops);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_selectedBusId == null || _selectedStopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un bus et un arrêt')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.assignStudentToBus(
            studentId: widget.student.id,
            busId: _selectedBusId!,
            stopId: _selectedStopId!,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: BgColors.dusk.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Affecter un bus', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
          Text('Élève : ${widget.student.fullName}', style: GoogleFonts.dmSans(color: BgColors.dusk.withValues(alpha: 0.7))),
          const SizedBox(height: 20),
          if (_buses.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedBusId,
              decoration: const InputDecoration(labelText: 'Bus *', prefixIcon: Icon(Icons.directions_bus_rounded)),
              items: _buses.map((b) => DropdownMenuItem(
                value: b.id,
                child: Text('${b.matricule} · ${b.model ?? ''} (${b.capacity} places)'),
              )).toList(),
              onChanged: (v) {
                setState(() => _selectedBusId = v);
                if (v != null) _loadStops(v);
              },
            )
          else
            const Center(child: Text('Aucun bus disponible')),
          const SizedBox(height: 14),
          if (_stops.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedStopId,
              decoration: const InputDecoration(labelText: 'Arrêt de prise en charge *', prefixIcon: Icon(Icons.location_on_rounded)),
              items: _stops.map((s) => DropdownMenuItem(
                value: s['id'].toString(),
                child: Text(s['name'] as String? ?? 'Arrêt'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedStopId = v),
            )
          else if (_selectedBusId != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: BgColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('Aucun arrêt configuré pour ce bus.', style: GoogleFonts.dmSans(color: BgColors.dusk)),
            ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
            child: _saving
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Affecter l\'élève', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
