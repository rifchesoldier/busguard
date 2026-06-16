enum StudentStatus { enAttente, aBord, arrive, absent }

class StudentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? schoolName;
  final String? className;
  final String? busId;
  final String? busMatricule;
  final String? stopName;
  final StudentStatus status;
  final String? photoUrl;
  final double? schoolLat;
  final double? schoolLng;

  const StudentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.schoolName,
    this.className,
    this.busId,
    this.busMatricule,
    this.stopName,
    this.status = StudentStatus.enAttente,
    this.photoUrl,
    this.schoolLat,
    this.schoolLng,
  });

  String get fullName => '$firstName $lastName';

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'].toString(),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      schoolName: json['school']?['name'] as String? ?? json['school_name'] as String?,
      className: json['class_name'] as String?,
      busId: json['assigned_bus_id']?.toString() ?? json['bus']?['id']?.toString(),
      busMatricule: json['bus']?['matricule'] as String?,
      stopName: json['stop']?['name'] as String?,
      status: _parseStatus(json['current_status'] as String? ?? 'en_attente'),
      photoUrl: json['photo_url'] as String?,
      schoolLat: double.tryParse(json['school']?['lat']?.toString() ?? ''),
      schoolLng: double.tryParse(json['school']?['lng']?.toString() ?? ''),
    );
  }

  static StudentStatus _parseStatus(String s) => switch (s) {
        'a_bord' => StudentStatus.aBord,
        'arrive' => StudentStatus.arrive,
        'absent' => StudentStatus.absent,
        _ => StudentStatus.enAttente,
      };

  String get statusLabel => switch (status) {
        StudentStatus.enAttente => 'En attente',
        StudentStatus.aBord => 'À bord',
        StudentStatus.arrive => 'Arrivé(e)',
        StudentStatus.absent => 'Absent(e)',
      };
}
