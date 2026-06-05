enum BusStatus { idle, enRoute, arrived, signalPerdu }

class BusPosition {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const BusPosition({required this.lat, required this.lng, required this.timestamp});
}

class BusModel {
  final String id;
  final String matricule;
  final String? model;
  final int capacity;
  final String? driverName;
  final BusStatus status;
  final BusPosition? position;
  final String? trafficAlert;
  final List<List<double>> routePolyline;

  const BusModel({
    required this.id,
    required this.matricule,
    this.model,
    this.capacity = 40,
    this.driverName,
    this.status = BusStatus.idle,
    this.position,
    this.trafficAlert,
    this.routePolyline = const [],
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: json['id'].toString(),
      matricule: json['matricule'] as String,
      model: json['model'] as String?,
      capacity: json['capacity'] as int? ?? 40,
      driverName: json['driver']?['name'] as String? ?? json['driver_name'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'idle'),
      position: json['last_lat'] != null
          ? BusPosition(
              lat: (json['last_lat'] as num).toDouble(),
              lng: (json['last_lng'] as num).toDouble(),
              timestamp: DateTime.tryParse(json['last_position_at']?.toString() ?? '') ?? DateTime.now(),
            )
          : null,
      trafficAlert: json['traffic_alert'] as String?,
    );
  }

  static BusStatus _parseStatus(String s) => switch (s) {
        'en_route' => BusStatus.enRoute,
        'arrived' => BusStatus.arrived,
        'signal_perdu' => BusStatus.signalPerdu,
        _ => BusStatus.idle,
      };

  String get statusLabel => switch (status) {
        BusStatus.idle => 'En attente',
        BusStatus.enRoute => 'En route',
        BusStatus.arrived => 'Arrivé',
        BusStatus.signalPerdu => 'Signal perdu',
      };

  BusModel copyWith({
    BusStatus? status,
    BusPosition? position,
    String? trafficAlert,
    List<List<double>>? routePolyline,
  }) =>
      BusModel(
        id: id,
        matricule: matricule,
        model: model,
        capacity: capacity,
        driverName: driverName,
        status: status ?? this.status,
        position: position ?? this.position,
        trafficAlert: trafficAlert ?? this.trafficAlert,
        routePolyline: routePolyline ?? this.routePolyline,
      );
}
