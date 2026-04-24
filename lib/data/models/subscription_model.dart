/// Subscription plan model (SubscriptionModel on the backend)
class SubscriptionPlanModel {
  final String id;
  final String modelCode;
  final String providerId;
  final String name;
  final String? description;
  final String modelType; // 'SESSION_BASED' | 'MONTHLY'
  final double price;
  final String currency;
  final int? durationDays;
  final int? sessionsIncluded;
  final List<String> features;
  final bool isActive;
  final int sortOrder;
  final SubscriptionProviderInfo? provider;

  const SubscriptionPlanModel({
    required this.id,
    required this.modelCode,
    required this.providerId,
    required this.name,
    this.description,
    required this.modelType,
    required this.price,
    this.currency = 'RWF',
    this.durationDays,
    this.sessionsIncluded,
    this.features = const [],
    this.isActive = true,
    this.sortOrder = 0,
    this.provider,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = rawFeatures is List
        ? rawFeatures.map((e) => e.toString()).toList()
        : <String>[];

    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? '',
      modelCode: json['modelCode']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      modelType: json['modelType']?.toString() ?? 'MONTHLY',
      price: _parseDouble(json['price']) ?? 0,
      currency: json['currency']?.toString() ?? 'RWF',
      durationDays: json['durationDays'] as int?,
      sessionsIncluded: json['sessionsIncluded'] as int?,
      features: features,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      provider: json['provider'] != null
          ? SubscriptionProviderInfo.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSessionBased => modelType == 'SESSION_BASED';
  bool get isMonthly => modelType == 'MONTHLY';

  String get typeLabel => isSessionBased ? 'Session-Based' : 'Monthly';

  String get durationLabel {
    if (isSessionBased && sessionsIncluded != null) {
      return '$sessionsIncluded session${sessionsIncluded! > 1 ? 's' : ''}';
    }
    if (isMonthly && durationDays != null) {
      final months = (durationDays! / 30).round();
      return months == 1 ? '1 month' : '$months months';
    }
    return 'Ongoing';
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class SubscriptionProviderInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? businessName;

  const SubscriptionProviderInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.businessName,
  });

  factory SubscriptionProviderInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionProviderInfo(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      businessName: json['businessName']?.toString(),
    );
  }
}

class SubscriptionCustomerInfo {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;

  const SubscriptionCustomerInfo({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
  });

  factory SubscriptionCustomerInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionCustomerInfo(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

/// An active subscription purchased by a pet owner (ProviderSubscription on backend)
class ProviderSubscriptionModel {
  final String id;
  final String subscriptionCode;
  final String customerId;
  final String providerId;
  final String modelId;
  final String status; // ACTIVE, EXPIRED, CANCELLED
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final int? sessionsRemaining;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;

  // Nested
  final SubscriptionPlanModel? model;
  final SubscriptionProviderInfo? provider;
  final SubscriptionCustomerInfo? customer;

  const ProviderSubscriptionModel({
    required this.id,
    required this.subscriptionCode,
    required this.customerId,
    required this.providerId,
    required this.modelId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    this.sessionsRemaining,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    this.model,
    this.provider,
    this.customer,
  });

  factory ProviderSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ProviderSubscriptionModel(
      id: json['id']?.toString() ?? '',
      subscriptionCode: json['subscriptionCode']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      modelId: json['modelId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ?? DateTime.now().add(const Duration(days: 30)),
      autoRenew: json['autoRenew'] as bool? ?? false,
      sessionsRemaining: json['sessionsRemaining'] as int?,
      cancelledAt: _parseDate(json['cancelledAt']),
      cancellationReason: json['cancellationReason']?.toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      model: json['model'] != null
          ? SubscriptionPlanModel.fromJson(json['model'] as Map<String, dynamic>)
          : null,
      provider: json['provider'] != null
          ? SubscriptionProviderInfo.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
      customer: json['customer'] != null
          ? SubscriptionCustomerInfo.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  bool get isCancelled => status == 'CANCELLED';

  bool get isExpiringSoon {
    if (!isActive) return false;
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    return daysLeft <= 3;
  }

  int get daysRemaining => endDate.difference(DateTime.now()).inDays.clamp(0, 9999);

  String get statusLabel {
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'EXPIRED':
        return 'Expired';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
