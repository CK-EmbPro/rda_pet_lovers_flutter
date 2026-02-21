// ignore_for_file: use_null_aware_elements
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/pet_service.dart' show PaginatedResponse;
import 'base_api_service.dart';

/// ServiceApiService — handles all `/services` API calls.
///
/// PUBLIC endpoints (no auth required):
///   - getAll, getById, getByProvider, getCategories
///
/// PROTECTED endpoints (require auth token):
///   - getMyServices, create, update, delete, toggleAvailability
class ServiceApiService extends BaseApiService {
  ServiceApiService(super.client);

  // ---------------------------------------------------------------------------
  // PUBLIC ENDPOINTS
  // ---------------------------------------------------------------------------

  /// Get all available services (public) — paginated.
  Future<PaginatedResponse<ServiceModel>> getAll({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? paymentType,
    String? search,
  }) async {
    return safeApiCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (paymentType != null) 'paymentType': paymentType,
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

  /// Get a single service by ID (public).
  Future<ServiceModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.services}/$id');
      return ServiceModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Get services by a specific provider ID (public).
  Future<List<ServiceModel>> getByProvider(String providerId, {
    int page = 1,
    int limit = 20,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.services}/provider/$providerId',
        queryParameters: {'page': page, 'limit': limit},
      );
      // May return { data, meta } or plain list
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['data'] ?? []) as List;
      return data.map((json) => ServiceModel.fromJson(json as Map<String, dynamic>)).toList();
    });
  }

  /// Get all service categories (public).
  Future<List<ServiceCategory>> getCategories() async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.services}/categories');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['data'] ?? []) as List;
      return data
          .map((json) => ServiceCategory.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // PROTECTED ENDPOINTS
  // ---------------------------------------------------------------------------

  /// Get the authenticated provider's own services.
  /// Returns paginated `{ data, meta }` wrapper from backend.
  Future<List<ServiceModel>> getMyServices({
    int page = 1,
    int limit = 50,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.services}/my-services',
        queryParameters: {'page': page, 'limit': limit},
      );

      // Backend returns { data: [...], meta: {...} }
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['data'] ?? []) as List;

      return data
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Create a new service (protected — requires SERVICES.WRITE permission).
  Future<ActionResponse<ServiceModel>> create({
    required String name,
    required double basePrice,
    String? description,
    String paymentType = 'PAY_UPFRONT',
    double? priceYoungPet,
    double? priceOldPet,
    int? durationMinutes,
    String? categoryId,
    bool requiresSubscription = false,
  }) async {
    return safeApiCall(() async {
      final body = <String, dynamic>{
        'name': name,
        'basePrice': basePrice,
        'paymentType': paymentType,
        if (description != null && description.isNotEmpty) 'description': description,
        if (priceYoungPet != null) 'priceYoungPet': priceYoungPet,
        if (priceOldPet != null) 'priceOldPet': priceOldPet,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (categoryId != null) 'categoryId': categoryId,
        if (requiresSubscription) 'requiresSubscription': requiresSubscription,
      };

      final response = await dio.post(ApiEndpoints.services, data: body);
      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ServiceModel.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  /// Update an existing service (protected — requires SERVICES.WRITE permission).
  /// [updates] should only contain the fields you want to change (partial update).
  Future<ActionResponse<ServiceModel>> update(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return safeApiCall(() async {
      final response = await dio.put(
        '${ApiEndpoints.services}/$id',
        data: updates,
      );
      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ServiceModel.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  /// Soft-delete a service (protected — requires SERVICES.DELETE permission).
  Future<ActionResponse<void>> delete(String id) async {
    return safeApiCall(() async {
      final response = await dio.delete('${ApiEndpoints.services}/$id');
      return ActionResponse.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'message': 'Service deleted successfully'},
        (_) => null,
      );
    });
  }

  /// Toggle a service's `isAvailable` flag (protected — requires SERVICES.WRITE).
  Future<ActionResponse<ServiceModel>> toggleAvailability(String id) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.services}/$id/toggle-availability',
      );
      return ActionResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ServiceModel.fromJson(json as Map<String, dynamic>),
      );
    });
  }
}
