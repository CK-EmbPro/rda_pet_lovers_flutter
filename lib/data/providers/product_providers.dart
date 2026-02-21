import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/pet_service.dart';
import '../services/product_service.dart';

/// Singleton ProductService provider
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(DioClient());
});

/// All products (public, paginated)
final allProductsProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<ProductModel>, ProductQueryParams>(
        (ref, params) async {
  final service = ref.read(productServiceProvider);
  return service.getAll(
    page: params.page,
    limit: params.limit,
    categoryId: params.categoryId,
    search: params.search,
    shopId: params.shopId,
    isFeatured: params.isFeatured,
  );
});

/// Products by shop (for shop owner portal)
final shopProductsProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<ProductModel>, String>((ref, shopId) async {
  final service = ref.read(productServiceProvider);
  return service.getByShop(shopId);
});

/// Single product detail
final productDetailProvider =
    FutureProvider.autoDispose.family<ProductModel, String>((ref, id) async {
  final service = ref.read(productServiceProvider);
  return service.getById(id);
});

/// Product CRUD state notifier
class ProductCrudNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductService _service;

  ProductCrudNotifier(this._service) : super(const AsyncValue.data(null));

  Future<ProductModel?> createProduct({
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
    state = const AsyncValue.loading();
    try {
      final product = await _service.create(
        shopId: shopId,
        name: name,
        price: price,
        stockQuantity: stockQuantity,
        description: description,
        categoryId: categoryId,
        discountPercentage: discountPercentage,
        sku: sku,
        isActive: isActive,
        isFeatured: isFeatured,
        images: images,
      );
      state = const AsyncValue.data(null);
      return product;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<ProductModel?> updateProduct(
      String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final product = await _service.update(id, updates);
      state = const AsyncValue.data(null);
      return product;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    try {
      await _service.delete(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<ProductModel?> updateStock(String id, int quantity) async {
    state = const AsyncValue.loading();
    try {
      final product = await _service.updateStock(id, quantity);
      state = const AsyncValue.data(null);
      return product;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final productCrudProvider =
    StateNotifierProvider<ProductCrudNotifier, AsyncValue<void>>((ref) {
  return ProductCrudNotifier(ref.read(productServiceProvider));
});

/// Query parameters for product listing
class ProductQueryParams {
  final int page;
  final int limit;
  final String? categoryId;
  final String? search;
  final String? shopId;
  final bool? isFeatured;

  const ProductQueryParams({
    this.page = 1,
    this.limit = 10,
    this.categoryId,
    this.search,
    this.shopId,
    this.isFeatured,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductQueryParams &&
          page == other.page &&
          limit == other.limit &&
          categoryId == other.categoryId &&
          search == other.search &&
          shopId == other.shopId &&
          isFeatured == other.isFeatured;

  @override
  int get hashCode =>
      Object.hash(page, limit, categoryId, search, shopId, isFeatured);
}
