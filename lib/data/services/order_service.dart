import 'package:flutter/foundation.dart';
import '../../core/api/dio_client.dart';
// ignore_for_file: use_null_aware_elements
import '../models/models.dart';
import '../services/pet_service.dart';
import 'base_api_service.dart';

/// Order API Service — handles order lifecycle.
/// All endpoints are protected.
class OrderService extends BaseApiService {
  OrderService(super.client);

  /// Create an order from cart (protected)
  Future<OrderModel> create({
    String? shopId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    return safeApiCall(() async {
      final data = <String, dynamic>{
        'items': items,
        if (shopId != null && shopId.isNotEmpty) 'shopId': shopId,
        if (notes != null) 'notes': notes,
      };
      debugPrint('[OrderService] Creating order: shopId=${shopId ?? "NULL"}, items=$items');
      final response = await dio.post(
        ApiEndpoints.orders,
        data: data,
      );
      debugPrint('[OrderService] Order created: ${response.data}');
      return OrderModel.fromJson(response.data);
    });
  }

  /// Get all orders (admin)
  Future<PaginatedResponse<OrderModel>> getAll({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => OrderModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get my orders as buyer (protected)
  Future<PaginatedResponse<OrderModel>> getMyOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.myOrders,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => OrderModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get seller orders (for shop owners) (protected)
  Future<PaginatedResponse<OrderModel>> getSellerOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.sellerOrders,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => OrderModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get order by ID (protected)
  Future<OrderModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.orders}/$id');
      return OrderModel.fromJson(response.data);
    });
  }

  /// Update order status (protected — seller/admin)
  Future<OrderModel> updateStatus(String id, String status) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.orders}/$id/status',
        data: {'status': status},
      );
      return OrderModel.fromJson(response.data);
    });
  }

  /// Cancel an order (protected)
  Future<void> cancel(String id, {String? reason}) async {
    return safeApiCall(() async {
      await dio.post(
        '${ApiEndpoints.orders}/$id/cancel',
        data: {
          'reason': reason ?? 'Cancelled by user',
        },
      );
    });
  }

}
