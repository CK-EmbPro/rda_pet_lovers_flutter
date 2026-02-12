import '../../core/api/dio_client.dart';
import '../services/pet_service.dart';
import 'base_api_service.dart';

/// Pet Listing Model for sale/adoption listings
class PetListingModel {
  final String id;
  final String listingCode;
  final String petId;
  final String listerId;
  final String listingType; // FOR_SALE, FOR_DONATION
  final double? price;
  final String? currency;
  final String? description;
  final String status; // ACTIVE, SOLD, ADOPTED, CANCELLED, EXPIRED
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Nested data
  final Map<String, dynamic>? pet;
  final Map<String, dynamic>? lister;

  PetListingModel({
    required this.id,
    required this.listingCode,
    required this.petId,
    required this.listerId,
    required this.listingType,
    this.price,
    this.currency,
    this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.pet,
    this.lister,
  });

  factory PetListingModel.fromJson(Map<String, dynamic> json) {
    return PetListingModel(
      id: json['id'] as String,
      listingCode: json['listingCode'] as String? ?? '',
      petId: json['petId'] as String,
      listerId: json['listerId'] as String,
      listingType: json['listingType'] as String,
      price: _parseDouble(json['price']),
      currency: json['currency'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      pet: json['pet'] as Map<String, dynamic>?,
      lister: json['lister'] as Map<String, dynamic>?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool get isForSale => listingType == 'FOR_SALE';
  bool get isForAdoption => listingType == 'FOR_DONATION';
  bool get isActive => status == 'ACTIVE';

  String get displayPrice {
    if (price == null) return 'Free';
    return '${currency ?? "RWF"} ${price!.toStringAsFixed(0)}';
  }
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

  /// Approve a listing (admin) (protected)
  Future<dynamic> approve(String listingId) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.petListings}/$listingId/approve',
      );
      return response.data;
    });
  }
}
