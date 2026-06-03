class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  Profile({required this.id, this.fullName, this.phone, this.avatarUrl});

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        fullName: map['full_name'] as String?,
        phone: map['phone'] as String?,
        avatarUrl: map['avatar_url'] as String?,
      );
}
