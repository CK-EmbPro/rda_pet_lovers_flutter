import '../../core/api/dio_client.dart';
import '../models/shop_model.dart';
import 'base_api_service.dart';

/// Category API Service — handles product and service categories.
/// All endpoints are public.
class CategoryService extends BaseApiService {
  CategoryService(super.client);

  /// Get all product categories (public)
  Future<List<CategoryModel>> getProductCategories() async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.productCategories);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get all service categories (public)
  Future<List<CategoryModel>> getServiceCategories() async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.serviceCategories);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }
}
