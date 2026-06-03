import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/alert.dart';
import '../utils/theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SupabaseService.getMyAlerts();
    if (mounted) setState(() { _alerts = list; _loading = false; });
  }

  Future<void> _markRead(AlertModel a) async {
    if (!a.read) {
      await SupabaseService.markAlertRead(a.id);
      _load();
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'pickup': return Icons.directions_bus;
      case 'dropoff': return Icons.school;
      case 'delay': return Icons.access_time;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _alerts.isEmpty
                ? const Center(child: Text('Aucune alerte'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) {
                      final a = _alerts[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: a.read
                                ? Colors.grey.shade300
                                : AppColors.yellow,
                            child: Icon(_icon(a.type),
                                color: a.read ? Colors.grey : AppColors.navy),
                          ),
                          title: Text(a.title,
                              style: TextStyle(
                                  fontWeight: a.read
                                      ? FontWeight.normal
                                      : FontWeight.bold)),
                          subtitle: Text(
                              '${a.message ?? ''}\n${DateFormat('dd/MM HH:mm').format(a.createdAt)}'),
                          isThreeLine: true,
                          onTap: () => _markRead(a),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
