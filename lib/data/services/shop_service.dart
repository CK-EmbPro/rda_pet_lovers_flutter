import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
// ignore_for_file: use_null_aware_elements
import '../models/models.dart';
import 'base_api_service.dart';
import 'pet_service.dart';

/// Shop API Service — handles all shop-related API calls.
/// Public endpoints: getAll, getById
/// Protected endpoints: create, update, delete, getMyShop, verifyShop
class ShopService extends BaseApiService {
  ShopService(super.client);

  /// Get all shops with pagination and filtering
  Future<PaginatedResponse<ShopModel>> getAll({
    int page = 1,
    int limit = 10,
    String? search,
    bool? isVerified,
    String? ownerId,
    bool? isActive,
  }) async {
    return safeApiCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isVerified != null) 'isVerified': isVerified,
        if (ownerId != null) 'ownerId': ownerId,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await dio.get(
        ApiEndpoints.shops,
        queryParameters: queryParams,
      );

      return PaginatedResponse.fromJson(
        response.data,
        (json) => ShopModel.fromJson(json),
      );
    });
  }

  /// Get shop by ID
  Future<ShopModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.shops}/$id');
      return ShopModel.fromJson(response.data);
    });
  }

  /// Get my shop (for shop owner)
  Future<ShopModel?> getMyShop() async {
    try {
      final response = await dio.get(ApiEndpoints.myShop);
      if (response.data == null) return null;
      // Handle array or object return — controller findByOwner may return list or object
      if (response.data is List && (response.data as List).isNotEmpty) {
        return ShopModel.fromJson((response.data as List).first);
      } else if (response.data is List) {
        return null;
      }
      return ShopModel.fromJson(response.data);
    } on DioException catch (e) {
      // Only return null if it's a 404 (Not Found)
      // If 403 (Forbidden), 500 (Server Error), etc., we should rethrow to show error in UI
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new shop
  Future<ShopModel> create({
    required String name,
    String? description,
    String? address,
    String? phone,
    String? email,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        ApiEndpoints.shops,
        data: {
          'name': name,
          'description': description,
          'address': address,
          'phone': phone,
          'email': email,
        },
      );
      return ShopModel.fromJson(response.data);
    });
  }

  /// Update a shop
  Future<ShopModel> update(String id, Map<String, dynamic> updates) async {
    return safeApiCall(() async {
      final response = await dio.put(
        '${ApiEndpoints.shops}/$id',
        data: updates,
      );
      return ShopModel.fromJson(response.data);
    });
  }

  /// Delete a shop
  Future<void> delete(String id) async {
    return safeApiCall(() async {
      await dio.delete('${ApiEndpoints.shops}/$id');
    });
  }

  /// Verify a shop (Admin)
  Future<void> verifyShop(String id, bool approved, {String? reason}) async {
    return safeApiCall(() async {
      await dio.post(
        '${ApiEndpoints.shops}/$id/verify',
        data: {
          'approved': approved,
          'reason': reason,
        },
      );
    });
  }
}
