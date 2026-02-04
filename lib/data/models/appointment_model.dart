import 'service_model.dart';

/// Appointment Model matching backend Appointment entity
class AppointmentModel {
  final String id;
  final String userId;
  final String providerId;
  final String serviceId;
  final String? petId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status; // PENDING, CONFIRMED, CANCELLED, COMPLETED, NO_SHOW
  final String? notes;
  final double? totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Nested data
  final ServiceModel? service;
  final PetBasicInfo? pet;
  final ProviderBasicInfo? provider;
  final UserBasicInfo? user;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.serviceId,
    this.petId,
    required this.scheduledAt,
    this.durationMinutes = 60,
    required this.status,
    this.notes,
    this.totalAmount,
    required this.createdAt,
    this.updatedAt,
    this.service,
    this.pet,
    this.provider,
    this.user,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      providerId: json['providerId'] as String,
      serviceId: json['serviceId'] as String,
      petId: json['petId'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      service: json['service'] != null
          ? ServiceModel.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      pet: json['pet'] != null
          ? PetBasicInfo.fromJson(json['pet'] as Map<String, dynamic>)
          : null,
      provider: json['provider'] != null
          ? ProviderBasicInfo.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? UserBasicInfo.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';

  String get displayStatus {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'COMPLETED':
        return 'Completed';
      case 'NO_SHOW':
        return 'No Show';
      default:
        return status;
    }
  }
}

/// Basic Pet Info for appointments
class PetBasicInfo {
  final String id;
  final String petCode;
  final String name;
  final String? breed;
  final String? imageUrl;

  PetBasicInfo({
    required this.id,
    required this.petCode,
    required this.name,
    this.breed,
    this.imageUrl,
  });

  factory PetBasicInfo.fromJson(Map<String, dynamic> json) {
    return PetBasicInfo(
      id: json['id'] as String,
      petCode: json['petCode'] as String,
      name: json['name'] as String,
      breed: json['breed']?['name'] as String? ?? json['breed'] as String?,
      imageUrl: (json['images'] as List?)?.firstOrNull as String?,
    );
  }
}

/// Basic Provider Info
class ProviderBasicInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? businessName;

  ProviderBasicInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.businessName,
  });

  factory ProviderBasicInfo.fromJson(Map<String, dynamic> json) {
    return ProviderBasicInfo(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      businessName: json['businessName'] as String?,
    );
  }
}

/// Basic User Info
class UserBasicInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;

  UserBasicInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
  });

  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
