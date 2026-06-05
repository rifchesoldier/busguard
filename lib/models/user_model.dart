enum UserRole { parent, driver, admin, superadmin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? firebaseUid;
  final String? schoolId;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.firebaseUid,
    this.schoolId,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: _parseRole(json['role'] as String? ?? 'parent'),
      firebaseUid: json['firebase_uid'] as String?,
      schoolId: json['school_id']?.toString(),
      token: token,
    );
  }

  static UserRole _parseRole(String role) => switch (role) {
        'driver' => UserRole.driver,
        'admin' => UserRole.admin,
        'superadmin' => UserRole.superadmin,
        _ => UserRole.parent,
      };

  bool get isParent => role == UserRole.parent;
  bool get isDriver => role == UserRole.driver;
}
