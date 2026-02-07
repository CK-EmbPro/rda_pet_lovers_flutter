import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

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

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(ProductModel product, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.id == product.id && item.type == 'PRODUCT');
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
  }

  void addPet(PetModel pet) {
    final existingIndex = state.indexWhere((item) => item.id == pet.id && item.type == 'PET');
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
          shopId: pet.ownerId, // For pets, we treat owner as shop
        ),
      ];
    }
  }

  void removeItem(String id, String type) {
    state = state.where((item) => !(item.id == id && item.type == type)).toList();
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
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
