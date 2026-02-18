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
      id: _extractString(json['id'], key: 'id') ?? '',
      providerId: _extractString(json['providerId'], key: 'id') ?? '',
      serviceType: _extractString(json['serviceType']) ?? _extractString(json['category'], key: 'name') ?? 'OTHER',
      name: _extractString(json['name']) ?? 'Unknown Service',
      description: _extractString(json['description']),
      fee: _parseDouble(json['basePrice']) ?? _parseDouble(json['fee']) ?? 0,
      priceYoungPet: _parseDouble(json['priceYoungPet']),
      priceOldPet: _parseDouble(json['priceOldPet']),
      durationMinutes: json['durationMinutes'] as int?,
      categoryId: _extractString(json['categoryId'], key: 'id'),
      paymentMethod: _extractString(json['paymentMethod']) ?? _extractString(json['paymentType']) ?? 'PAY_BEFORE',
      paymentType: _extractString(json['paymentType']),
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

/// Safely extract a String from a value that might be a String, Map, or null.
/// If it's a Map, extracts [key] (default 'name') from it.
String? _extractString(dynamic value, {String key = 'name'}) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) return value[key]?.toString();
  return value.toString();
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
      id: _extractString(json['id'], key: 'id') ?? '',
      fullName: _extractString(json['fullName'], key: 'fullName') ?? _extractString(json['user'], key: 'firstName') ?? 'Provider',
      avatarUrl: _extractString(json['avatarUrl']),
      phone: _extractString(json['phone']),
      email: _extractString(json['email']),
      specialty: _extractString(json['specialty']),
      businessName: _extractString(json['businessName']),
      workingHours: _extractString(json['workingHours']),
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}
