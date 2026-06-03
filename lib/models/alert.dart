class AlertModel {
  final String id;
  final String userId;
  final String? childId;
  final String type;
  final String title;
  final String? message;
  final bool read;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    this.childId,
    required this.type,
    required this.title,
    this.message,
    required this.read,
    required this.createdAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) => AlertModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        childId: map['child_id'] as String?,
        type: map['type'] as String,
        title: map['title'] as String,
        message: map['message'] as String?,
        read: map['read'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
