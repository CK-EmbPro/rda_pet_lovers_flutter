import '../../core/api/dio_client.dart';
import '../models/models.dart';
// ignore_for_file: use_null_aware_elements
import '../services/pet_service.dart';
import 'base_api_service.dart';

/// Product API Service — handles all product-related API calls.
/// Public endpoints: getAll, getById, getByShop
/// Protected endpoints: create, update, delete, updateStock
class ProductService extends BaseApiService {
  ProductService(super.client);

  /// Get all products (public) — paginated with filters
  Future<PaginatedResponse<ProductModel>> getAll({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? search,
    String? shopId,
    bool? isFeatured,
  }) async {
    return safeApiCall(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (shopId != null) 'shopId': shopId,
        if (isFeatured != null) 'isFeatured': isFeatured,
      };

      final response = await dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => ProductModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get product by ID (public)
  Future<ProductModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.products}/$id');
      return ProductModel.fromJson(response.data);
    });
  }

  /// Get products by shop (public)
  Future<PaginatedResponse<ProductModel>> getByShop(
    String shopId, {
    int page = 1,
    int limit = 20,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.products}/shop/$shopId',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => ProductModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Create a product (protected)
  Future<ProductModel> create({
    required String shopId,
    required String name,
    required double price,
    required int stockQuantity,
    String? description,
    String? categoryId,
    double? discountPercentage,
    String? sku,
    bool? isActive,
    bool? isFeatured,
    List<String>? images,
  }) async {
    return safeApiCall(() async {
      final data = <String, dynamic>{
        'shopId': shopId,
        'name': name,
        'price': price,
        'stockQuantity': stockQuantity,
        if (description != null) 'description': description,
        if (categoryId != null) 'categoryId': categoryId,
        if (discountPercentage != null) 'discountPercentage': discountPercentage,
        if (sku != null) 'sku': sku,
        if (isActive != null) 'isActive': isActive,
        if (isFeatured != null) 'isFeatured': isFeatured,
        if (images != null) 'images': images,
      };

      final response = await dio.post(ApiEndpoints.products, data: data);
      return ProductModel.fromJson(response.data);
    });
  }

  /// Update a product (protected)
  Future<ProductModel> update(String id, Map<String, dynamic> updates) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.products}/$id',
        data: updates,
      );
      return ProductModel.fromJson(response.data);
    });
  }

  /// Delete a product (protected)
  Future<void> delete(String id) async {
    return safeApiCall(() async {
      await dio.delete('${ApiEndpoints.products}/$id');
    });
  }

  /// Update stock quantity (protected)
  Future<ProductModel> updateStock(String id, int quantity) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.products}/$id/stock',
        data: {'quantity': quantity},
      );
      return ProductModel.fromJson(response.data);
    });
  }
}
