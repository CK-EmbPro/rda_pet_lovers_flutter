import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/shop_model.dart';
import '../services/order_service.dart';
import '../services/pet_service.dart';

/// Singleton OrderService provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(DioClient());
});

/// My orders as buyer
final myOrdersProvider = FutureProvider.autoDispose
    .family<List<OrderModel>, String?>((ref, status) async {
  final service = ref.read(orderServiceProvider);
  final result = await service.getMyOrders(limit: 50, status: status);
  return result.data;
});

/// Seller orders (for shop owners)
final sellerOrdersProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<OrderModel>, String?>((ref, status) async {
  final service = ref.read(orderServiceProvider);
  return service.getSellerOrders(status: status);
});

/// Seller orders for reports (fetch more items)
final sellerReportOrdersProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<OrderModel>, int>((ref, limit) async {
  final service = ref.read(orderServiceProvider);
  return service.getSellerOrders(limit: limit); // removed status filter to get all
});

/// Single order detail
final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderModel, String>((ref, id) async {
  final service = ref.read(orderServiceProvider);
  return service.getById(id);
});

/// Order action notifier (create, update status, cancel)
class OrderActionNotifier extends StateNotifier<AsyncValue<void>> {
  final OrderService _service;

  OrderActionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<OrderModel?> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    String? shippingAddress,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final order = await _service.create(
        shopId: shopId,
        items: items,
        shippingAddress: shippingAddress,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return order;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateStatus(id, status);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelOrder(String id) async {
    state = const AsyncValue.loading();
    try {
      await _service.cancel(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addTracking(String id, String trackingNumber) async {
    state = const AsyncValue.loading();
    try {
      await _service.addTracking(id, trackingNumber);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderActionProvider =
    StateNotifierProvider<OrderActionNotifier, AsyncValue<void>>((ref) {
  return OrderActionNotifier(ref.read(orderServiceProvider));
});
