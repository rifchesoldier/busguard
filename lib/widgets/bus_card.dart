import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../utils/theme.dart';

class BusCard extends StatelessWidget {
  final Bus bus;
  const BusCard({super.key, required this.bus});

  Color _statusColor() {
    switch (bus.status) {
      case 'en_route': return AppColors.success;
      case 'delayed': return AppColors.danger;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.navy,
          child: const Icon(Icons.directions_bus, color: Colors.white),
        ),
        title: Text(bus.plate,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${bus.routeName ?? "Ligne ?"}\nChauffeur : ${bus.driverName ?? "?"}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor().withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(bus.status ?? 'idle',
                  style: TextStyle(
                      color: _statusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            if (bus.etaMinutes != null) ...[
              const SizedBox(height: 4),
              Text('${bus.etaMinutes} min',
                  style: const TextStyle(fontSize: 12)),
            ]
          ],
        ),
      ),
    );
  }
}
