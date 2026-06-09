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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _buses = await context.read<AuthService>().api.myBuses();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BgColors.cream,
      appBar: AppBar(
        title: const Text('Gestion des bus'),
        backgroundColor: BgColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: BgColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, style: GoogleFonts.dmSans(color: BgColors.danger), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: BgColors.terracotta,
                  child: _buses.isEmpty
                      ? _empty()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _buses.length,
                          itemBuilder: (_, i) => _BusTile(bus: _buses[i], onRefresh: _load),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BusFormPage(onSaved: _load),
        fullscreenDialog: true,
      ),
    );
  }
}

// ── Tuile bus ──────────────────────────────────────────────────────────────────

class _BusTile extends StatelessWidget {
  final BusModel bus;
  final VoidCallback onRefresh;
  const _BusTile({required this.bus, required this.onRefresh});

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
            icon: const Icon(Icons.edit_rounded, color: BgColors.dusk),
            tooltip: 'Modifier',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _BusEditPage(bus: bus, onSaved: onRefresh),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: BgColors.danger),
            tooltip: 'Supprimer',
            onPressed: () async {
              final ok = await _confirmDelete(context);
              if (ok == true && context.mounted) {
                try {
                  await context.read<AuthService>().api.deleteBus(bus.id);
                  onRefresh();
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

// ── Page modification bus ──────────────────────────────────────────────────────

class _BusEditPage extends StatefulWidget {
  final BusModel bus;
  final VoidCallback onSaved;
  const _BusEditPage({required this.bus, required this.onSaved});
  @override
  State<_BusEditPage> createState() => _BusEditPageState();
}

class _BusEditPageState extends State<_BusEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _model;
  late final TextEditingController _capacity;
  List<UserModel> _drivers = [];
  String? _selectedDriverId;
  bool _saving = false;

  // Routes & arrêts existants
  List<Map<String, dynamic>> _routes = [];
  bool _loadingRoutes = true;

  // Nouveaux arrêts à ajouter (dans la 1ère route existante ou nouvelle)
  final List<TextEditingController> _newStops = [];
  String _routeName = 'Ligne principale';
  String _direction = 'matin';
  String _departureTime = '07:00';

  @override
  void initState() {
    super.initState();
    _model = TextEditingController(text: widget.bus.model ?? '');
    _capacity = TextEditingController(text: widget.bus.capacity.toString());
    _loadDrivers();
    _loadRoutes();
  }

  @override
  void dispose() {
    _model.dispose();
    _capacity.dispose();
    for (final c in _newStops) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    try {
      final drivers = await context.read<AuthService>().api.getUsers(role: 'driver');
      if (mounted) {
        setState(() {
          _drivers = drivers;
          _selectedDriverId = widget.bus.driverName != null
              ? drivers.firstWhere((d) => d.name == widget.bus.driverName, orElse: () => drivers.first).id
              : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRoutes() async {
    setState(() => _loadingRoutes = true);
    try {
      final routes = await context.read<AuthService>().api.getRoutesForBus(widget.bus.id);
      if (mounted) {
        setState(() {
          _routes = routes;
          _loadingRoutes = false;
          if (routes.isNotEmpty) {
            _routeName = routes.first['name'] as String? ?? 'Ligne principale';
            _direction = routes.first['direction'] as String? ?? 'matin';
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRoutes = false);
    }
  }

  // Supprimer un arrêt existant via suppression de la route et recréation
  Future<void> _deleteStop(Map<String, dynamic> route, Map<String, dynamic> stop) async {
    final routeId = route['id'].toString();
    final currentStops = (route['stops'] as List).cast<Map<String, dynamic>>();
    final remaining = currentStops.where((s) => s['id'].toString() != stop['id'].toString()).toList();

    if (remaining.isEmpty) {
      // Si plus d'arrêts, supprimer la route entière
      try {
        await context.read<AuthService>().api.deleteRoute(routeId);
        await _loadRoutes();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: BgColors.danger),
        );
      }
      return;
    }

    // Supprimer l'ancienne route et recréer avec les arrêts restants
    try {
      final api = context.read<AuthService>().api;
      final schoolId = (route['school_id'] ?? widget.bus.id).toString();
      await api.deleteRoute(routeId);
      await api.createRoute(
        busId: widget.bus.id,
        schoolId: schoolId,
        name: route['name'] as String? ?? 'Ligne principale',
        direction: route['direction'] as String? ?? 'matin',
        stops: remaining.asMap().entries.map((e) => {
          'name': e.value['name'],
          'order': e.key + 1,
          'lat': double.tryParse(e.value['lat']?.toString() ?? '0') ?? 0.0,
          'lng': double.tryParse(e.value['lng']?.toString() ?? '0') ?? 0.0,
        }).toList(),
      );
      await _loadRoutes();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: BgColors.danger),
      );
    }
  }

  void _addNewStopField() => setState(() => _newStops.add(TextEditingController()));
  void _removeNewStop(int i) { _newStops[i].dispose(); setState(() => _newStops.removeAt(i)); }

  Future<void> _saveNewStops() async {
    final names = _newStops.map((c) => c.text.trim()).where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return;

    try {
      final api = context.read<AuthService>().api;

      if (_routes.isNotEmpty) {
        // Ajouter aux arrêts existants de la 1ère route
        final route = _routes.first;
        final routeId = route['id'].toString();
        final existing = (route['stops'] as List).cast<Map<String, dynamic>>();
        final allStops = [
          ...existing.asMap().entries.map((e) => {
            'name': e.value['name'],
            'order': e.key + 1,
            'lat': double.tryParse(e.value['lat']?.toString() ?? '0') ?? 0.0,
            'lng': double.tryParse(e.value['lng']?.toString() ?? '0') ?? 0.0,
          }),
          ...names.asMap().entries.map((e) => {
            'name': e.value,
            'order': existing.length + e.key + 1,
            'lat': 0.0,
            'lng': 0.0,
          }),
        ];
        final schoolId = (route['school_id'] ?? '').toString();
        await api.deleteRoute(routeId);
        await api.createRoute(
          busId: widget.bus.id,
          schoolId: schoolId,
          name: route['name'] as String? ?? _routeName,
          direction: route['direction'] as String? ?? _direction,
          stops: allStops,
        );
      } else {
        // Créer une nouvelle route avec les nouveaux arrêts
        // Récupérer le school_id du bus via les buses
        final buses = await api.myBuses();
        final thisBus = buses.firstWhere((b) => b.id == widget.bus.id, orElse: () => buses.first);
        // On n'a pas schoolId dans BusModel, on utilise une valeur par défaut
        // Le backend doit avoir le school_id du bus
        await api.createRoute(
          busId: widget.bus.id,
          schoolId: '1', // sera corrigé par le backend via le bus
          name: _routeName,
          direction: _direction,
          stops: names.asMap().entries.map((e) => {
            'name': e.value,
            'order': e.key + 1,
            'lat': 0.0,
            'lng': 0.0,
          }).toList(),
        );
      }

      for (final c in _newStops) { c.dispose(); }
      _newStops.clear();
      await _loadRoutes();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrêts ajoutés avec succès.'), backgroundColor: BgColors.success),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: BgColors.danger),
      );
    }
  }

  Future<void> _saveBusInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.updateBus(
        busId: widget.bus.id,
        model: _model.text.trim().isEmpty ? null : _model.text.trim(),
        capacity: int.tryParse(_capacity.text),
        driverId: _selectedDriverId,
      );
      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bus ${widget.bus.matricule} modifié.'), backgroundColor: BgColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: BgColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BgColors.cream,
      appBar: AppBar(
        title: Text('Modifier ${widget.bus.matricule}'),
        backgroundColor: BgColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [

            // ── Matricule (lecture seule) ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BgColors.dusk.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BgColors.dusk.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.directions_bus_rounded, color: BgColors.dusk),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Matricule', style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.6))),
                  Text(widget.bus.matricule, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: BgColors.dusk.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Non modifiable', style: GoogleFonts.dmSans(fontSize: 10, color: BgColors.dusk.withValues(alpha: 0.5))),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Infos bus ──────────────────────────────────────────────
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Modèle', prefixIcon: Icon(Icons.commute_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacité *', prefixIcon: Icon(Icons.people_rounded)),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 14),
            if (_drivers.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedDriverId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Chauffeur assigné', prefixIcon: Icon(Icons.person_pin_rounded)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                  ..._drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _selectedDriverId = v),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _saveBusInfo,
              style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Enregistrer les modifications', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // ── Arrêts desservis ───────────────────────────────────────
            Row(children: [
              const Icon(Icons.route_rounded, color: BgColors.terracotta, size: 20),
              const SizedBox(width: 8),
              Text('Arrêts desservis', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: BgColors.ink)),
            ]),
            const SizedBox(height: 12),

            if (_loadingRoutes)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_routes.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: BgColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Text('Aucun arrêt configuré pour ce bus.', style: GoogleFonts.dmSans(color: BgColors.dusk)),
              )
            else
              ..._routes.expand((route) {
                final stops = (route['stops'] as List? ?? []).cast<Map<String, dynamic>>();
                return [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: BgColors.ink.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${route['name'] ?? 'Ligne'} · ${route['direction'] == 'matin' ? 'Matin' : 'Soir'}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...stops.asMap().entries.map((entry) {
                    final i = entry.key;
                    final stop = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BgTheme.glassCard(),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: BgColors.terracotta.withValues(alpha: 0.15),
                          child: Text('${i + 1}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: BgColors.terracotta)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(stop['name'] as String? ?? 'Arrêt', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600))),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: BgColors.danger, size: 20),
                          tooltip: 'Supprimer cet arrêt',
                          onPressed: () => _deleteStop(route, stop),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ]),
                    );
                  }),
                  const SizedBox(height: 8),
                ];
              }),

            const SizedBox(height: 16),

            // ── Ajouter de nouveaux arrêts ─────────────────────────────
            Row(children: [
              const Icon(Icons.add_location_alt_rounded, color: BgColors.terracotta, size: 18),
              const SizedBox(width: 6),
              Text('Ajouter des arrêts', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: BgColors.terracotta)),
            ]),
            const SizedBox(height: 10),

            if (_routes.isEmpty) ...[
              TextFormField(
                initialValue: _routeName,
                decoration: const InputDecoration(labelText: 'Nom de la ligne', prefixIcon: Icon(Icons.edit_road_rounded)),
                onChanged: (v) => _routeName = v,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _direction,
                decoration: const InputDecoration(labelText: 'Direction'),
                items: const [
                  DropdownMenuItem(value: 'matin', child: Text('Matin')),
                  DropdownMenuItem(value: 'soir', child: Text('Soir')),
                ],
                onChanged: (v) => setState(() => _direction = v ?? 'matin'),
              ),
              const SizedBox(height: 10),
            ],

            ...List.generate(_newStops.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: BgColors.sage.withValues(alpha: 0.15),
                  child: Text('+', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: BgColors.sage)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _newStops[i],
                    decoration: InputDecoration(labelText: 'Nouvel arrêt ${i + 1}', prefixIcon: const Icon(Icons.location_on_rounded)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: BgColors.danger, size: 20),
                  onPressed: () => _removeNewStop(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            )),

            TextButton.icon(
              onPressed: _addNewStopField,
              icon: const Icon(Icons.add, color: BgColors.terracotta),
              label: Text('Ajouter un arrêt', style: GoogleFonts.outfit(color: BgColors.terracotta, fontWeight: FontWeight.w600)),
            ),

            if (_newStops.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saveNewStops,
                style: ElevatedButton.styleFrom(backgroundColor: BgColors.sage),
                child: Text('Enregistrer les arrêts', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Page création bus ──────────────────────────────────────────────────────────

class _BusFormPage extends StatefulWidget {
  final VoidCallback onSaved;
  const _BusFormPage({required this.onSaved});
  @override
  State<_BusFormPage> createState() => _BusFormPageState();
}

class _BusFormPageState extends State<_BusFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _matricule = TextEditingController();
  final _model = TextEditingController();
  final _capacity = TextEditingController(text: '35');
  final _routeName = TextEditingController(text: 'Ligne principale');
  final _departureTime = TextEditingController(text: '07:00');
  List<SchoolModel> _schools = [];
  List<UserModel> _drivers = [];
  String? _selectedSchoolId;
  String? _selectedDriverId;
  String _direction = 'matin';
  bool _saving = false;
  bool _loadingData = true;
  String? _loadError;
  final List<Map<String, TextEditingController>> _stops = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _addStop();
  }

  @override
  void dispose() {
    _matricule.dispose();
    _model.dispose();
    _capacity.dispose();
    _routeName.dispose();
    _departureTime.dispose();
    for (final s in _stops) { s['name']!.dispose(); }
    super.dispose();
  }

  void _addStop() => setState(() => _stops.add({'name': TextEditingController()}));

  void _removeStop(int i) {
    if (_stops.length <= 1) return;
    _stops[i]['name']!.dispose();
    setState(() => _stops.removeAt(i));
  }

  Future<void> _loadData() async {
    setState(() { _loadingData = true; _loadError = null; });
    final api = context.read<AuthService>().api;
    final user = context.read<AuthService>().user;
    try {
      final schools = await api.getSchools();
      final drivers = await api.getUsers(role: 'driver');
      if (mounted) {
        setState(() {
          _schools = schools;
          _drivers = drivers;
          _loadingData = false;
          if (user?.schoolId != null) {
            _selectedSchoolId = user!.schoolId;
          } else if (schools.length == 1) {
            _selectedSchoolId = schools.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loadingData = false; _loadError = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez sélectionner une école')));
      return;
    }
    final stopNames = _stops.map((s) => s['name']!.text.trim()).toList();
    if (stopNames.any((n) => n.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remplissez le nom de tous les arrêts')));
      return;
    }
    setState(() => _saving = true);
    try {
      final api = context.read<AuthService>().api;
      final bus = await api.createBus(
        schoolId: _selectedSchoolId!,
        matricule: _matricule.text.trim(),
        model: _model.text.trim().isEmpty ? null : _model.text.trim(),
        capacity: int.tryParse(_capacity.text),
        driverId: _selectedDriverId,
      );
      final stopsData = stopNames.asMap().entries.map((e) => {
        'name': e.value, 'order': e.key + 1, 'lat': 0.0, 'lng': 0.0,
      }).toList();
      await api.createRoute(
        busId: bus.id,
        schoolId: _selectedSchoolId!,
        name: _routeName.text.trim().isEmpty ? 'Ligne principale' : _routeName.text.trim(),
        direction: _direction,
        scheduledStart: _departureTime.text.trim().isEmpty ? null : _departureTime.text.trim(),
        stops: stopsData,
      );
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
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
    return Scaffold(
      backgroundColor: BgColors.cream,
      appBar: AppBar(
        title: const Text('Enregistrer un bus'),
        backgroundColor: BgColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
            if (_loadingData)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
            else if (_loadError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: BgColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Erreur : $_loadError', style: GoogleFonts.dmSans(color: BgColors.danger, fontSize: 12)),
                  TextButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh, size: 16), label: const Text('Réessayer'),
                      style: TextButton.styleFrom(foregroundColor: BgColors.terracotta)),
                ]),
              )
            else if (_schools.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: BgColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('Aucune école disponible. Créez une école d\'abord.', style: GoogleFonts.dmSans(color: BgColors.dusk)),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedSchoolId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'École *', prefixIcon: Icon(Icons.school_rounded)),
                items: _schools.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedSchoolId = v),
                validator: (v) => v == null ? 'Requis' : null,
              ),
            const SizedBox(height: 14),
            if (_drivers.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedDriverId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Chauffeur assigné', prefixIcon: Icon(Icons.person_pin_rounded)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                  ..._drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _selectedDriverId = v),
              ),
            const SizedBox(height: 24),
            Row(children: [
              const Icon(Icons.route_rounded, color: BgColors.terracotta, size: 20),
              const SizedBox(width: 8),
              Text('Ligne & Arrêts', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: BgColors.ink)),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _routeName,
              decoration: const InputDecoration(labelText: 'Nom de la ligne', prefixIcon: Icon(Icons.edit_road_rounded)),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _departureTime,
                  decoration: const InputDecoration(labelText: 'Heure de départ', prefixIcon: Icon(Icons.access_time_rounded)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _direction,
                  decoration: const InputDecoration(labelText: 'Direction'),
                  items: const [
                    DropdownMenuItem(value: 'matin', child: Text('Matin')),
                    DropdownMenuItem(value: 'soir', child: Text('Soir')),
                  ],
                  onChanged: (v) => setState(() => _direction = v ?? 'matin'),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            ...List.generate(_stops.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: BgColors.terracotta.withValues(alpha: 0.15),
                  child: Text('${i + 1}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: BgColors.terracotta)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stops[i]['name'],
                    decoration: InputDecoration(labelText: 'Arrêt ${i + 1}', prefixIcon: const Icon(Icons.location_on_rounded)),
                    validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                  ),
                ),
                if (_stops.length > 1)
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: BgColors.danger), onPressed: () => _removeStop(i)),
              ]),
            )),
            TextButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add_location_alt_rounded, color: BgColors.terracotta),
              label: Text('Ajouter un arrêt', style: GoogleFonts.outfit(color: BgColors.terracotta, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: BgColors.terracotta),
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Enregistrer le bus', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
