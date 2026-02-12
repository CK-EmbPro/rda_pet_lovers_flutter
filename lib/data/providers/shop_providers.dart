import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/pet_service.dart';
import '../services/shop_service.dart';

/// Singleton ShopService provider
final shopServiceProvider = Provider<ShopService>((ref) {
  return ShopService(DioClient());
});

/// All shops (paginated)
final allShopsProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<ShopModel>, ShopQueryParams>(
        (ref, params) async {
  final service = ref.read(shopServiceProvider);
  return service.getAll(
    page: params.page,
    limit: params.limit,
    search: params.search,
    isVerified: params.isVerified,
    isActive: params.isActive,
  );
});

/// Single shop detail by ID
final shopDetailProvider =
    FutureProvider.autoDispose.family<ShopModel, String>((ref, id) async {
  final service = ref.read(shopServiceProvider);
  return service.getById(id);
});

/// My Shop (for shop owner)
final myShopProvider = FutureProvider.autoDispose<ShopModel?>((ref) async {
  final service = ref.read(shopServiceProvider);
  return service.getMyShop();
});

/// Shop CRUD notifier
class ShopCrudNotifier extends StateNotifier<AsyncValue<void>> {
  final ShopService _service;

  ShopCrudNotifier(this._service) : super(const AsyncValue.data(null));

  Future<ShopModel?> createShop({
    required String name,
    String? description,
    String? address,
    String? phone,
    String? email,
  }) async {
    state = const AsyncValue.loading();
    try {
      final shop = await _service.create(
        name: name,
        description: description,
        address: address,
        phone: phone,
        email: email,
      );
      state = const AsyncValue.data(null);
      return shop;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<ShopModel?> updateShop(
      String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final shop = await _service.update(id, updates);
      state = const AsyncValue.data(null);
      return shop;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteShop(String id) async {
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
}

final shopCrudProvider =
    StateNotifierProvider<ShopCrudNotifier, AsyncValue<void>>((ref) {
  return ShopCrudNotifier(ref.read(shopServiceProvider));
});

/// Query parameters for shop listing
class ShopQueryParams {
  final int page;
  final int limit;
  final String? search;
  final bool? isVerified;
  final bool? isActive;

  const ShopQueryParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.isVerified,
    this.isActive,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopQueryParams &&
          page == other.page &&
          limit == other.limit &&
          search == other.search &&
          isVerified == other.isVerified &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      Object.hash(page, limit, search, isVerified, isActive);
}
