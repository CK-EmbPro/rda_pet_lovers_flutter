import '../../core/api/dio_client.dart';
// ignore_for_file: use_null_aware_elements
import '../models/models.dart';
import '../services/pet_service.dart';
import 'base_api_service.dart';

/// Pet Service API Service — handles pet service-related API calls (walking, grooming, etc.).
/// Public endpoints: getAll, getById
/// Protected endpoints: create, update, delete, toggleAvailability, getMyServices
class ServiceApiService extends BaseApiService {
  ServiceApiService(super.client);

  /// Get all services (public) — paginated
  Future<PaginatedResponse<ServiceModel>> getAll({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? serviceType,
    String? search,
  }) async {
    return safeApiCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (serviceType != null) 'serviceType': serviceType,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await dio.get(
        ApiEndpoints.services,
        queryParameters: queryParams,
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => ServiceModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get service by ID (public)
  Future<ServiceModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.services}/$id');
      return ServiceModel.fromJson(response.data);
    });
  }

  /// Get services by provider (public)
  Future<List<ServiceModel>> getByProvider(String providerId) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.services}/provider/$providerId',
      );
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    });
  }

  /// Create a new service (protected)
  Future<ServiceModel> create({
    required String name,
    required double basePrice,
    String? description,
    double? priceYoungPet,
    double? priceOldPet,
    int? durationMinutes,
    String? categoryId,
    String? paymentType,
    bool? requiresSubscription,
  }) async {
    return safeApiCall(() async {
      final data = <String, dynamic>{
        'name': name,
        'basePrice': basePrice,
        if (description != null) 'description': description,
        if (priceYoungPet != null) 'priceYoungPet': priceYoungPet,
        if (priceOldPet != null) 'priceOldPet': priceOldPet,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (categoryId != null) 'categoryId': categoryId,
        if (paymentType != null) 'paymentType': paymentType,
        if (requiresSubscription != null) 'requiresSubscription': requiresSubscription,
      };

      final response = await dio.post(ApiEndpoints.services, data: data);
      return ServiceModel.fromJson(response.data);
    });
  }

  /// Update a service (protected)
  Future<ServiceModel> update(String id, Map<String, dynamic> updates) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.services}/$id',
        data: updates,
      );
      return ServiceModel.fromJson(response.data);
    });
  }

  /// Delete a service (protected)
  Future<void> delete(String id) async {
    return safeApiCall(() async {
      await dio.delete('${ApiEndpoints.services}/$id');
    });
  }

  /// Toggle service availability (protected)
  Future<ServiceModel> toggleAvailability(String id) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.services}/$id/toggle-availability',
      );
      return ServiceModel.fromJson(response.data);
    });
  }

  /// Get my services (protected — uses authenticated provider identity)
  // @protected — requires SERVICES.READ permission
  Future<List<ServiceModel>> getMyServices() async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.services}/my-services');
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((json) => ServiceModel.fromJson(json)).toList();
    });
  }
}
