/// Service Model matching backend PetService entity
class ServiceModel {
  final String id;
  final String providerId;
  final String serviceType; // WALKING, GROOMING, TRAINING, VETERINARY
  final String name;
  final String? description;
  final double fee;
  final String paymentMethod; // PAY_BEFORE, PAY_AFTER
  final bool isActive;
  final DateTime createdAt;

  // Nested data
  final ProviderInfo? provider;

  ServiceModel({
    required this.id,
    required this.providerId,
    required this.serviceType,
    required this.name,
    this.description,
    required this.fee,
    required this.paymentMethod,
    this.isActive = true,
    required this.createdAt,
    this.provider,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      serviceType: json['serviceType'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      fee: (json['fee'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String? ?? 'PAY_BEFORE',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      provider: json['provider'] != null
          ? ProviderInfo.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'serviceType': serviceType,
      'name': name,
      'description': description,
      'fee': fee,
      'paymentMethod': paymentMethod,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayServiceType {
    switch (serviceType) {
      case 'WALKING':
        return 'Pet Walking';
      case 'GROOMING':
        return 'Pet Grooming';
      case 'TRAINING':
        return 'Pet Training';
      case 'VETERINARY':
        return 'Veterinary';
      default:
        return serviceType;
    }
  }

  String get iconName {
    switch (serviceType) {
      case 'WALKING':
        return 'footprints';
      case 'GROOMING':
        return 'scissors';
      case 'TRAINING':
        return 'coach';
      case 'VETERINARY':
        return 'medical';
      default:
        return 'services';
    }
  }
}

/// Provider Info (for service cards)
class ProviderInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final String? specialty;
  final String? businessName;
  final String? workingHours;
  final bool isAvailable;

  ProviderInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.email,
    this.specialty,
    this.businessName,
    this.workingHours,
    this.isAvailable = true,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      specialty: json['specialty'] as String?,
      businessName: json['businessName'] as String?,
      workingHours: json['workingHours'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}
