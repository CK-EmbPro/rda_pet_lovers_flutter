/// Notification model matching backend Notification entity
class NotificationModel {
  final String id;
  final String notificationCode;
  final String userId;
  final String type; // BOOKING_UPDATE, ORDER_STATUS, PAYMENT_EVENT, etc.
  final String title;
  final String message;
  final String? actionUrl;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final List<String> channels;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.notificationCode,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.actionUrl,
    this.relatedEntityType,
    this.relatedEntityId,
    this.channels = const [],
    this.isRead = false,
    this.readAt,
    this.metadata,
    required this.createdAt,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      notificationCode: json['notificationCode'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM_WARNING',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      actionUrl: json['actionUrl'] as String?,
      relatedEntityType: json['relatedEntityType'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      channels: (json['channels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      notificationCode: notificationCode,
      userId: userId,
      type: type,
      title: title,
      message: message,
      actionUrl: actionUrl,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      channels: channels,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}
