import 'package:flutter/material.dart';
import '../models/child.dart';
import '../utils/theme.dart';

class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onDelete;
  const ChildCard({super.key, required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.yellow,
          child: Text(child.fullName[0].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.navy, fontWeight: FontWeight.bold)),
        ),
        title: Text(child.fullName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${child.school ?? "École ?"} • ${child.grade ?? "Classe ?"}\nArrêt : ${child.stopName ?? "?"}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
