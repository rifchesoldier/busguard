import 'package:flutter/material.dart';

enum AlertType { traffic, absent, arrived, anomalie, info }

class AlertModel {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? childName;

  const AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    this.childName,
  });

  IconData get icon => switch (type) {
        AlertType.traffic => Icons.traffic_rounded,
        AlertType.absent => Icons.person_off_rounded,
        AlertType.arrived => Icons.school_rounded,
        AlertType.anomalie => Icons.warning_amber_rounded,
        AlertType.info => Icons.info_outline_rounded,
      };

  Color get color => switch (type) {
        AlertType.traffic => const Color(0xFFE63946),
        AlertType.absent => const Color(0xFFE07A5F),
        AlertType.arrived => const Color(0xFF2A9D8F),
        AlertType.anomalie => const Color(0xFFF4A261),
        AlertType.info => const Color(0xFF3D405B),
      };
}
