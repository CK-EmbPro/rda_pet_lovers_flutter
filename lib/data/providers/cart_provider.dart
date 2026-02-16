import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';

import '../services/cart_service.dart';

/// Singleton CartApiService provider
final cartApiServiceProvider = Provider<CartApiService>((ref) {
  return CartApiService(DioClient());
});

/// Cart item model used by the notifier (backward-compatible with old CartItem)
class CartItem {
  final String id;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  final String type; // 'PRODUCT' or 'PET'
  final String shopId;

  CartItem({
    required this.id,
    required this.name,
    this.image,
    required this.price,
    this.quantity = 1,
    required this.type,
    required this.shopId,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      image: image,
      price: price,
      quantity: quantity ?? this.quantity,
      type: type,
      shopId: shopId,
    );
  }
}

/// Cart state notifier — syncs with backend API.
/// Falls back to local-only if API calls fail (e.g. not authenticated).
class CartNotifier extends StateNotifier<List<CartItem>> {
  final CartApiService _cartService;
  bool _initialized = false;

  CartNotifier(this._cartService) : super([]);

  /// Load cart from backend
  Future<void> loadCart() async {
    if (_initialized) return;
    try {
      final items = await _cartService.getCart();
      state = items
          .map((item) => CartItem(
                id: item.productId,
                name: item.productName,
                image: item.imageUrl,
                price: item.price,
                quantity: item.quantity,
                type: 'PRODUCT',
                shopId: item.shopId,
              ))
          .toList();
      _initialized = true;
    } catch (_) {
      // If API fails (not logged in), keep local cart
    }
  }

  void addProduct(ProductModel product, {int quantity = 1}) {
    final existingIndex = state.indexWhere(
        (item) => item.id == product.id && item.type == 'PRODUCT');
    if (existingIndex != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + quantity)
          else
            state[i],
      ];
    } else {
      state = [
        ...state,
        CartItem(
          id: product.id,
          name: product.name,
          image: product.mainImage,
          price: product.effectivePrice,
          quantity: quantity,
          type: 'PRODUCT',
          shopId: product.shopId,
        ),
      ];
    }

    // Sync with backend (fire and forget)
    _cartService
        .addItem(productId: product.id, quantity: quantity)
        .catchError((_) {});
  }

  void addPet(PetModel pet) {
    final existingIndex =
        state.indexWhere((item) => item.id == pet.id && item.type == 'PET');
    if (existingIndex == -1) {
      state = [
        ...state,
        CartItem(
          id: pet.id,
          name: pet.name,
          image: pet.displayImage,
          price: pet.price ?? 0,
          quantity: 1,
          type: 'PET',
          shopId: pet.ownerId,
        ),
      ];
    }
  }

  void removeItem(String id, String type) {
    state =
        state.where((item) => !(item.id == id && item.type == type)).toList();

    // Sync with backend
    _cartService.removeItem(id).catchError((_) {});
  }

  void updateQuantity(String id, String type, int quantity) {
    if (quantity <= 0) {
      removeItem(id, type);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == id && item.type == type)
          item.copyWith(quantity: quantity)
        else
          item,
    ];

    // Sync with backend
    _cartService.updateItem(id, quantity).catchError((_) {});
  }

  void clear() {
    state = [];
    _cartService.clearCart().catchError((_) {});
  }

  double get total =>
      state.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final cartService = ref.read(cartApiServiceProvider);
  return CartNotifier(cartService);
});
