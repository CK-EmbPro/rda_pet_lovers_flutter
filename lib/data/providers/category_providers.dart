import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/shop_model.dart';
import '../services/category_service.dart';

/// Singleton CategoryService provider
final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(DioClient());
});

/// Product categories (public)
final productCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.read(categoryServiceProvider);
  return service.getProductCategories();
});

/// Service categories (public)
final serviceCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final service = ref.read(categoryServiceProvider);
  return service.getServiceCategories();
});
