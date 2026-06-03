class Child {
  final String id;
  final String parentId;
  final String fullName;
  final String? grade;
  final String? school;
  final String? stopName;
  final String? busId;
  final String? photoUrl;

  Child({
    required this.id,
    required this.parentId,
    required this.fullName,
    this.grade,
    this.school,
    this.stopName,
    this.busId,
    this.photoUrl,
  });

  factory Child.fromMap(Map<String, dynamic> map) => Child(
        id: map['id'] as String,
        parentId: map['parent_id'] as String,
        fullName: map['full_name'] as String,
        grade: map['grade'] as String?,
        school: map['school'] as String?,
        stopName: map['stop_name'] as String?,
        busId: map['bus_id'] as String?,
        photoUrl: map['photo_url'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'parent_id': parentId,
        'full_name': fullName,
        if (grade != null) 'grade': grade,
        if (school != null) 'school': school,
        if (stopName != null) 'stop_name': stopName,
        if (busId != null) 'bus_id': busId,
        if (photoUrl != null) 'photo_url': photoUrl,
      };
}
