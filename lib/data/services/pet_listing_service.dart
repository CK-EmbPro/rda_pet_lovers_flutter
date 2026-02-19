import '../../core/api/dio_client.dart';
// ignore_for_file: use_null_aware_elements
import '../services/pet_service.dart';
import 'base_api_service.dart';

/// Pet Listing Model — aligned with backend PetListing entity.
/// Backend listingType values: SELL | DONATE
/// Backend status values: PUBLISHED | DRAFT | SOLD | ADOPTED | EXPIRED
class PetListingModel {
  final String id;
  final String listingCode;
  final String petId;
  final String ownerId; // ✅ backend field is 'ownerId', not 'listerId'
  final String listingType; // SELL | DONATE
  final double? price;
  final String? currency;
  final String? description;
  final String? locationId;
  final int viewCount;
  final int inquiryCount;
  final String status; // PUBLISHED | DRAFT | SOLD | ADOPTED | EXPIRED
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Nested relations from backend
  final Map<String, dynamic>? pet;
  final Map<String, dynamic>? owner;
  final Map<String, dynamic>? location;

  PetListingModel({
    required this.id,
    required this.listingCode,
    required this.petId,
    required this.ownerId,
    required this.listingType,
    this.price,
    this.currency,
    this.description,
    this.locationId,
    this.viewCount = 0,
    this.inquiryCount = 0,
    required this.status,
    this.publishedAt,
    this.expiresAt,
    required this.createdAt,
    this.updatedAt,
    this.pet,
    this.owner,
    this.location,
  });

  factory PetListingModel.fromJson(Map<String, dynamic> json) {
    return PetListingModel(
      id: json['id'] as String? ?? '',
      listingCode: json['listingCode'] as String? ?? '',
      petId: json['petId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '', // ✅ correct field
      listingType: json['listingType'] as String? ?? 'SELL', // ✅ SELL | DONATE
      price: _parseDouble(json['price']),
      currency: json['currency'] as String?,
      description: json['description'] as String?,
      locationId: json['locationId'] as String?,
      viewCount: (json['viewCount'] as int?) ?? 0,
      inquiryCount: (json['inquiryCount'] as int?) ?? 0,
      status: json['status'] as String? ?? 'PUBLISHED', // ✅ PUBLISHED not ACTIVE
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      pet: json['pet'] as Map<String, dynamic>?,
      owner: json['owner'] as Map<String, dynamic>?,
      location: json['location'] as Map<String, dynamic>?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ✅ Correct enum checks matching backend values
  bool get isForSale => listingType == 'SELL';
  bool get isForAdoption => listingType == 'DONATE';
  bool get isPublished => status == 'PUBLISHED';
  bool get isSold => status == 'SOLD';
  bool get isAdopted => status == 'ADOPTED';

  // Convenience pet data extractors
  String get petName => (pet?['name'] as String?) ?? 'Unknown Pet';
  String? get petImage {
    final images = pet?['images'] as List?;
    if (images != null && images.isNotEmpty) return images.first as String?;
    return null;
  }
  String get petSpecies => (pet?['species']?['name'] as String?) ?? '';
  String get ownerName => (owner?['fullName'] as String?) ?? 'Unknown Owner';
  String? get ownerAvatar => owner?['avatarUrl'] as String?;

  String get displayPrice {
    if (price == null || !isForSale) return 'Free';
    final formatted = price!.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${currency ?? "RWF"} $formatted';
  }

  String get listingTypeLabel => isForSale ? 'For Sale' : 'For Adoption';
}

/// Pet Listing API Service — handles selling and adoption.
/// Public: getAll, getForSale, getForAdoption
/// Protected: getMyListings, purchase, adopt, approve
class PetListingService extends BaseApiService {
  PetListingService(super.client);

  /// Get all listings (public)
  Future<PaginatedResponse<PetListingModel>> getAll({
    int page = 1,
    int limit = 10,
    String? type,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.petListings,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (type != null) 'type': type,
        },
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => PetListingModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get for-sale listings (public)
  Future<PaginatedResponse<PetListingModel>> getForSale({
    int page = 1,
    int limit = 10,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.petListingsForSale,
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => PetListingModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get for-adoption listings (public)
  Future<PaginatedResponse<PetListingModel>> getForAdoption({
    int page = 1,
    int limit = 10,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.petListingsForAdoption,
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => PetListingModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get my listings (protected)
  Future<PaginatedResponse<PetListingModel>> getMyListings({
    int page = 1,
    int limit = 20,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.petListingsMyListings,
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => PetListingModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Purchase a pet listing (protected)
  Future<dynamic> purchase(String listingId) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.petListings}/$listingId/purchase',
      );
      return response.data;
    });
  }

  /// Adopt from a listing (protected)
  Future<dynamic> adopt(String listingId) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.petListings}/$listingId/adopt',
      );
      return response.data;
    });
  }


}
