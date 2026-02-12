import '../../core/api/dio_client.dart';
import '../models/shop_model.dart';
import 'base_api_service.dart';

/// Cart API Service — syncs cart with backend.
/// All endpoints are protected (authenticated user).
class CartApiService extends BaseApiService {
  CartApiService(super.client);

  /// Get current user's cart
  Future<List<CartItemModel>> getCart() async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.cart);
      final data = response.data;

      // Backend may return { items: [...] } or just [...]
      final List<dynamic> items = data is List
          ? data
          : (data['items'] ?? data['data'] ?? []);

      return items
          .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Add item to cart
  Future<dynamic> addItem({
    required String productId,
    int quantity = 1,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.cart}/items',
        data: {
          'productId': productId,
          'quantity': quantity,
        },
      );
      return response.data;
    });
  }

  /// Update cart item quantity
  Future<dynamic> updateItem(String itemId, int quantity) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.cart}/items/$itemId',
        data: {'quantity': quantity},
      );
      return response.data;
    });
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    return safeApiCall(() async {
      await dio.delete('${ApiEndpoints.cart}/items/$itemId');
    });
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    return safeApiCall(() async {
      await dio.delete('${ApiEndpoints.cart}/clear');
    });
  }
}
