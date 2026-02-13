/// Service Model matching backend PetService entity
class ServiceModel {
  final String id;
  final String providerId;
  final String serviceType; // WALKING, GROOMING, TRAINING, VETERINARY
  final String name;
  final String? description;
  final double fee; // Maps to backend 'basePrice'
  final double? priceYoungPet;
  final double? priceOldPet;
  final int? durationMinutes;
  final String? categoryId;
  final String paymentMethod; // PAY_BEFORE, PAY_AFTER
  final String? paymentType; // Backend enum
  final bool? requiresSubscription;
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
    this.priceYoungPet,
    this.priceOldPet,
    this.durationMinutes,
    this.categoryId,
    required this.paymentMethod,
    this.paymentType,
    this.requiresSubscription,
    this.isActive = true,
    required this.createdAt,
    this.provider,
  });

  factory ServiceModel.empty() {
    return ServiceModel(
      id: '',
      providerId: '',
      serviceType: '',
      name: '',
      fee: 0,
      paymentMethod: 'PAY_BEFORE',
      createdAt: DateTime.now(),
    );
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      serviceType: json['serviceType'] as String? ?? json['category']?['name'] as String? ?? 'OTHER',
      name: json['name'] as String,
      description: json['description'] as String?,
      fee: _parseDouble(json['basePrice']) ?? _parseDouble(json['fee']) ?? 0,
      priceYoungPet: _parseDouble(json['priceYoungPet']),
      priceOldPet: _parseDouble(json['priceOldPet']),
      durationMinutes: json['durationMinutes'] as int?,
      categoryId: json['categoryId'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? json['paymentType'] as String? ?? 'PAY_BEFORE',
      paymentType: json['paymentType'] as String?,
      requiresSubscription: json['requiresSubscription'] as bool?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      provider: json['provider'] != null
          ? ProviderInfo.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'serviceType': serviceType,
      'name': name,
      'description': description,
      'basePrice': fee,
      'priceYoungPet': priceYoungPet,
      'priceOldPet': priceOldPet,
      'durationMinutes': durationMinutes,
      'categoryId': categoryId,
      'paymentType': paymentType ?? paymentMethod,
      'requiresSubscription': requiresSubscription,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create DTO for submission to backend
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'basePrice': fee,
      if (description != null) 'description': description,
      if (priceYoungPet != null) 'priceYoungPet': priceYoungPet,
      if (priceOldPet != null) 'priceOldPet': priceOldPet,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (categoryId != null) 'categoryId': categoryId,
      if (paymentType != null) 'paymentType': paymentType,
      if (requiresSubscription != null) 'requiresSubscription': requiresSubscription,
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
