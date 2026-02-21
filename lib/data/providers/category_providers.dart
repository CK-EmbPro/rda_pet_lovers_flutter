import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/base_api_service.dart';
import '../models/shop_model.dart'; // Import CategoryModel

class CategoryService extends BaseApiService {
  CategoryService(super.client);

  Future<List<CategoryModel>> getAllCategories() async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.products}/categories');
      final List<dynamic> data = response.data;
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    });
  }
}

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(DioClient());
});

final productCategoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.read(categoryServiceProvider);
  return service.getAllCategories();
});
