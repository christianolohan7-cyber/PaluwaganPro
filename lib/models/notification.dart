class Notification {
  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.actorUserId,
    this.groupId,
    this.paymentProofId,
    this.contributionId,
    this.round,
    this.readAt,
    this.metadata,
  });

  final int id;
  final String userId;
  final String? actorUserId;
  final int? groupId;
  final int? paymentProofId;
  final int? contributionId;
  final int? round;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  Notification copyWith({bool? isRead, DateTime? readAt}) {
    return Notification(
      id: id,
      userId: userId,
      actorUserId: actorUserId,
      groupId: groupId,
      paymentProofId: paymentProofId,
      contributionId: contributionId,
      round: round,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata,
    );
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: (map['id'] as num).toInt(),
      userId: map['user_id'].toString(),
      actorUserId: map['actor_user_id']?.toString(),
      groupId: (map['group_id'] as num?)?.toInt(),
      paymentProofId: (map['payment_proof_id'] as num?)?.toInt(),
      contributionId: (map['contribution_id'] as num?)?.toInt(),
      round: (map['round'] as num?)?.toInt(),
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String)
          : null,
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }
}
