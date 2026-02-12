import '../../core/api/dio_client.dart';
import '../models/models.dart';
import 'base_api_service.dart';

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final List<dynamic> rawData = json['data'] ?? [];
    final meta = json['meta'] ?? json;
    return PaginatedResponse(
      data: rawData.map((item) => fromJsonT(item as Map<String, dynamic>)).toList(),
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 10,
      total: meta['total'] as int? ?? 0,
      totalPages: meta['totalPages'] as int? ?? 0,
    );
  }
}

/// Pet API Service — handles all pet-related API calls.
/// Public endpoints: getAll, getById
/// Protected endpoints: create, update, delete, getMyPets, listForSale, listForDonation, cancelListing
class PetService extends BaseApiService {
  PetService(super.client);

  /// Get all pets (public) — paginated with optional filters
  Future<PaginatedResponse<PetModel>> getAll({
    int page = 1,
    int limit = 10,
    String? speciesId,
    String? breedId,
    String? gender,
    String? locationId,
    String? search,
  }) async {
    return safeApiCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (speciesId != null) 'speciesId': speciesId,
        if (breedId != null) 'breedId': breedId,
        if (gender != null) 'gender': gender,
        if (locationId != null) 'locationId': locationId,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await dio.get(
        ApiEndpoints.pets,
        queryParameters: queryParams,
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => PetModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get pet by ID (public) — includes vaccinations and listings
  Future<PetModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.pets}/$id');
      return PetModel.fromJson(response.data);
    });
  }

  /// Get current user's pets (protected)
  Future<PaginatedResponse<PetModel>> getMyPets({
    int page = 1,
    int limit = 20,
  }) async {
    return safeApiCall(() async {
      try {
        final response = await dio.get(
          ApiEndpoints.myPets,
          queryParameters: {'page': page, 'limit': limit},
        );

        final List<dynamic> rawData = response.data['data'] ?? [];
        final meta = response.data['meta'] ?? {};

        return PaginatedResponse(
          data: rawData.map((json) {
            try {
              return PetModel.fromJson(json);
            } catch (e, stack) {
              print('Error parsing pet: $e');
              print('JSON: $json');
              print(stack);
              rethrow;
            }
          }).toList(),
          page: meta['page'] ?? page,
          limit: meta['limit'] ?? limit,
          total: meta['total'] ?? 0,
          totalPages: meta['totalPages'] ?? 0,
        );
      } catch (e) {
        print('Error fetching my pets: $e');
        rethrow;
      }
    });
  }

  /// Create a new pet (protected)
  Future<PetModel> create({
    required String name,
    required String speciesId,
    required String gender,
    String? breedId,
    double? weightKg,
    int? ageYears,
    String? birthDate,
    String? locationId,
    String? nationality,
    List<String>? images,
    List<String>? videos,
    String? description,
    String? healthSummary,
  }) async {
    return safeApiCall(() async {
      final data = <String, dynamic>{
        'name': name,
        'speciesId': speciesId,
        'gender': gender,
        if (breedId != null) 'breedId': breedId,
        if (weightKg != null) 'weightKg': weightKg,
        if (ageYears != null) 'ageYears': ageYears,
        if (birthDate != null) 'birthDate': birthDate,
        if (locationId != null) 'locationId': locationId,
        if (nationality != null) 'nationality': nationality,
        if (images != null) 'images': images,
        if (videos != null) 'videos': videos,
        if (description != null) 'description': description,
        if (healthSummary != null) 'healthSummary': healthSummary,
      };

      final response = await dio.post(ApiEndpoints.pets, data: data);
      return PetModel.fromJson(response.data);
    });
  }

  /// Update a pet (protected)
  Future<PetModel> update(String id, Map<String, dynamic> updates) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.pets}/$id',
        data: updates,
      );
      return PetModel.fromJson(response.data);
    });
  }

  /// Delete a pet (protected)
  Future<void> delete(String id) async {
    return safeApiCall(() async {
      await dio.delete('${ApiEndpoints.pets}/$id');
    });
  }

  /// List pet for sale (protected)
  Future<dynamic> listForSale(String petId, {
    required double price,
    String? description,
    String? currency,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.pets}/$petId/list-for-sale',
        data: {
          'price': price,
          if (description != null) 'description': description,
          'currency': currency ?? 'RWF',
        },
      );
      return response.data;
    });
  }

  /// List pet for donation (protected)
  Future<dynamic> listForDonation(String petId, {
    String? description,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.pets}/$petId/list-for-donation',
        data: {
          if (description != null) 'description': description,
        },
      );
      return response.data;
    });
  }

  /// Cancel a listing (protected)
  Future<dynamic> cancelListing(String petId) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.pets}/$petId/cancel-listing',
      );
      return response.data;
    });
  }

  /// Transfer ownership (protected)
  Future<dynamic> transferOwnership(String petId, String toUserId) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.pets}/$petId/transfer-ownership',
        data: {'toUserId': toUserId},
      );
      return response.data;
    });
  }

  /// Get all pet species (public)
  Future<List<SpeciesModel>> getSpecies() async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.petSpecies);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data
          .map((json) => SpeciesModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get all breeds (public)
  Future<List<BreedModel>> getBreeds({String? speciesId}) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.petBreeds,
        queryParameters: {if (speciesId != null) 'speciesId': speciesId},
      );
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data
          .map((json) => BreedModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }
}
