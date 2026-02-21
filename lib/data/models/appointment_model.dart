import 'service_model.dart';

/// Appointment Model matching backend Appointment entity
class AppointmentModel {
  final String id;
  final String userId;
  final String providerId;
  final String serviceId;
  final String? petId;
  final DateTime scheduledAt;
  final String? scheduledTime; // Backend sends separate time string
  final int durationMinutes;
  final String status; // PENDING, ACCEPTED, CANCELLED, COMPLETED, NO_SHOW
  final String? notes;
  final String? customerNotes;
  final String? providerNotes;
  final String? cancellationReason;
  final double? totalAmount;
  final double? servicePrice;
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
    this.scheduledTime,
    this.durationMinutes = 60,
    required this.status,
    this.notes,
    this.customerNotes,
    this.providerNotes,
    this.cancellationReason,
    this.totalAmount,
    this.servicePrice,
    required this.createdAt,
    this.updatedAt,
    this.service,
    this.pet,
    this.provider,
    this.user,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] ?? json['petOwnerId'])?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      petId: json['petId']?.toString(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt']?.toString() ?? DateTime.now().toIso8601String())
          : (json['scheduledDate'] != null
              ? _parseDateTime(json['scheduledDate']?.toString() ?? '', json['scheduledTime']?.toString())
              : DateTime.now()),
      scheduledTime: json['scheduledTime']?.toString(),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      notes: json['notes']?.toString(),
      customerNotes: json['customerNotes']?.toString(),
      providerNotes: json['providerNotes']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      totalAmount: _parseDouble(json['totalAmount']),
      servicePrice: _parseDouble(json['servicePrice']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
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

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';

  String get displayStatus {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
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

  static DateTime _parseDateTime(String dateStr, String? timeStr) {
    if (timeStr == null) return DateTime.parse(dateStr);
    try {
      // dateStr is likely "2023-10-27T00:00:00.000Z" or "2023-10-27"
      // timeStr is "14:30"
      final date = DateTime.parse(dateStr);
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
      return date;
    } catch (_) {
      return DateTime.parse(dateStr);
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
      id: json['id']?.toString() ?? '',
      petCode: json['petCode']?.toString() ?? 'Unknown',
      name: json['name']?.toString() ?? 'Unknown',
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
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Provider',
      avatarUrl: json['avatarUrl']?.toString(),
      businessName: json['businessName']?.toString(),
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
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'User',
      avatarUrl: json['avatarUrl']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}
