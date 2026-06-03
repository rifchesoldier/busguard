import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/child.dart';
import '../models/bus.dart';
import '../models/alert.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/bus_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Child> _children = [];
  List<Bus> _buses = [];
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getMyChildren(),
        SupabaseService.getAllBuses(),
        SupabaseService.getMyAlerts(),
      ]);
      setState(() {
        _children = results[0] as List<Child>;
        _buses = results[1] as List<Bus>;
        _alerts = results[2] as List<AlertModel>;
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final unread = _alerts.where((a) => !a.read).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: StatCard(
                              icon: Icons.child_care,
                              label: 'Enfants',
                              value: '${_children.length}',
                              color: AppColors.navy)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: StatCard(
                              icon: Icons.directions_bus,
                              label: 'Bus actifs',
                              value: '${_buses.length}',
                              color: AppColors.yellow)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                      icon: Icons.notifications_active,
                      label: 'Alertes non lues',
                      value: '$unread',
                      color: AppColors.danger),
                  const SizedBox(height: 24),
                  const Text('Bus en circulation',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_buses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Aucun bus disponible')),
                    )
                  else
                    ..._buses.map((b) => BusCard(bus: b)),
                ],
              ),
      ),
    );
  }
}
