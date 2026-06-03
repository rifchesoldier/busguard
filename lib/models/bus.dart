class Bus {
  final String id;
  final String plate;
  final String? routeName;
  final String? driverName;
  final double? lat;
  final double? lng;
  final String? status;
  final int? etaMinutes;

  Bus({
    required this.id,
    required this.plate,
    this.routeName,
    this.driverName,
    this.lat,
    this.lng,
    this.status,
    this.etaMinutes,
  });

  factory Bus.fromMap(Map<String, dynamic> map) => Bus(
        id: map['id'] as String,
        plate: map['plate'] as String,
        routeName: map['route_name'] as String?,
        driverName: map['driver_name'] as String?,
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        status: map['status'] as String?,
        etaMinutes: map['eta_minutes'] as int?,
      );
}
