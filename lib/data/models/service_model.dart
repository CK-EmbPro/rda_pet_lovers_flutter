/// Service Category Model — matches backend ServiceCategory entity
class ServiceCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isActive = true,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'isActive': isActive,
      };
}

/// Service Model — mirrors backend `Service` entity exactly.
/// Backend field names are used as the canonical source of truth.
class ServiceModel {
  final String id;
  final String serviceCode;
  final String providerId;
  final String? categoryId;
  final String name;
  final String? description;
  final double basePrice;
  final String currency;
  final String paymentType; // PAY_UPFRONT | PAY_AFTER | SUBSCRIPTION
  final double? priceYoungPet;
  final double? priceOldPet;
  final int? durationMinutes;
  final bool isAvailable;
  final bool requiresSubscription;
  final DateTime createdAt;

  // Nested (optional — depends on which endpoint is called)
  final ServiceCategory? category;
  final ProviderInfo? provider;

  const ServiceModel({
    required this.id,
    required this.serviceCode,
    required this.providerId,
    this.categoryId,
    required this.name,
    this.description,
    required this.basePrice,
    this.currency = 'RWF',
    this.paymentType = 'PAY_UPFRONT',
    this.priceYoungPet,
    this.priceOldPet,
    this.durationMinutes,
    this.isAvailable = true,
    this.requiresSubscription = false,
    required this.createdAt,
    this.category,
    this.provider,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      serviceCode: json['serviceCode']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      name: json['name']?.toString() ?? 'Unknown Service',
      description: json['description']?.toString(),
      basePrice: _parseDouble(json['basePrice']) ?? 0.0,
      currency: json['currency']?.toString() ?? 'RWF',
      paymentType: json['paymentType']?.toString() ?? 'PAY_UPFRONT',
      priceYoungPet: _parseDouble(json['priceYoungPet']),
      priceOldPet: _parseDouble(json['priceOldPet']),
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? ''),
      isAvailable: json['isAvailable'] as bool? ?? true,
      requiresSubscription: json['requiresSubscription'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] != null
          ? ServiceCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
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

  /// Build the correct payload for creating or updating a service.
  /// Only includes non-null optional fields.
  Map<String, dynamic> toCreateDto() {
    return {
      'name': name,
      'basePrice': basePrice,
      if (description != null && description!.isNotEmpty) 'description': description,
      'paymentType': paymentType,
      if (priceYoungPet != null) 'priceYoungPet': priceYoungPet,
      if (priceOldPet != null) 'priceOldPet': priceOldPet,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (categoryId != null) 'categoryId': categoryId,
      if (requiresSubscription) 'requiresSubscription': requiresSubscription,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceCode': serviceCode,
      'providerId': providerId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'currency': currency,
      'paymentType': paymentType,
      'priceYoungPet': priceYoungPet,
      'priceOldPet': priceOldPet,
      'durationMinutes': durationMinutes,
      'isAvailable': isAvailable,
      'requiresSubscription': requiresSubscription,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Human-readable payment type label
  String get paymentTypeLabel {
    switch (paymentType) {
      case 'PAY_UPFRONT':
        return 'Pay Upfront';
      case 'PAY_AFTER':
        return 'Pay After';
      case 'SUBSCRIPTION':
        return 'Subscription';
      default:
        return paymentType;
    }
  }

  /// Duration formatted for display
  String get durationLabel {
    if (durationMinutes == null) return 'N/A';
    if (durationMinutes! < 60) return '${durationMinutes} min';
    final h = durationMinutes! ~/ 60;
    final m = durationMinutes! % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }
}

/// Provider Info — nested inside service responses
class ProviderInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final String? title;
  final String? titleDescription;
  final double? rating;
  final String? workingHours;

  const ProviderInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.email,
    this.title,
    this.titleDescription,
    this.rating,
    this.workingHours,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Provider',
      avatarUrl: json['avatarUrl']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      title: json['title']?.toString(),
      titleDescription: json['titleDescription']?.toString(),
      rating: ServiceModel._parseDouble(json['rating']),
      workingHours: json['workingHours']?.toString(),
    );
  }
}
