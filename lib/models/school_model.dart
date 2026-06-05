class SchoolModel {
  final String id;
  final String name;
  final String city;
  final String? address;
  final double? lat;
  final double? lng;
  final bool isActive;
  final List<String> availableClasses;

  const SchoolModel({
    required this.id,
    required this.name,
    required this.city,
    this.address,
    this.lat,
    this.lng,
    this.isActive = true,
    this.availableClasses = const [],
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    final rawClasses = json['available_classes'];
    List<String> classes = [];
    if (rawClasses is List) {
      classes = rawClasses.map((e) => e.toString()).toList();
    }
    return SchoolModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      city: json['city'] as String? ?? 'Dakar',
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      availableClasses: classes,
    );
  }
}
