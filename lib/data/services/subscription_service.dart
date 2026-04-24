import '../../core/api/dio_client.dart';
import '../models/models.dart';
import 'base_api_service.dart';

/// Subscription API service — wraps all /subscriptions/* endpoints.
class SubscriptionService extends BaseApiService {
  SubscriptionService(super.client);

  // ─── Plan browsing (public) ──────────────────────────────────────────────

  /// Get all subscription plan models (optionally filtered by providerId / modelType).
  Future<List<SubscriptionPlanModel>> getModels({
    String? providerId,
    String? modelType,
    bool activeOnly = true,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.subscriptionModels,
        queryParameters: {
          if (providerId != null) 'providerId': providerId,
          if (modelType != null) 'modelType': modelType,
          'activeOnly': activeOnly,
          'limit': 50,
        },
      );
      final raw = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      final list = raw is List ? raw : [raw];
      return list
          .map((j) => SubscriptionPlanModel.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get all active plans offered by a specific provider.
  Future<List<SubscriptionPlanModel>> getProviderModels(String providerId) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.subscriptionModels}/provider/$providerId',
      );
      final raw = response.data is List ? response.data : (response.data['data'] ?? []);
      return (raw as List)
          .map((j) => SubscriptionPlanModel.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  // ─── Pet owner subscription management ──────────────────────────────────

  /// Subscribe to a plan. Payment is handled automatically on the backend.
  /// Returns the new ProviderSubscriptionModel on success.
  Future<ProviderSubscriptionModel> subscribe({
    required String modelId,
    bool autoRenew = false,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.subscriptions}/subscribe',
        data: {'modelId': modelId, 'autoRenew': autoRenew},
      );
      final subJson = response.data['subscription'] ?? response.data;
      return ProviderSubscriptionModel.fromJson(subJson as Map<String, dynamic>);
    });
  }

  /// Get all subscriptions for the authenticated pet owner.
  Future<List<ProviderSubscriptionModel>> getMySubscriptions({String? status}) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.mySubscriptions,
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      final raw = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return (raw as List)
          .map((j) => ProviderSubscriptionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get a single subscription by ID.
  Future<ProviderSubscriptionModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.subscriptions}/$id');
      return ProviderSubscriptionModel.fromJson(
          response.data as Map<String, dynamic>);
    });
  }

  /// Cancel a subscription.
  Future<void> cancel(String id, {String? reason}) async {
    return safeApiCall(() async {
      await dio.post(
        '${ApiEndpoints.subscriptions}/$id/cancel',
        data: reason != null ? {'reason': reason} : {},
      );
    });
  }

  /// Toggle auto-renew on a subscription.
  Future<ProviderSubscriptionModel> toggleAutoRenew(String id) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.subscriptions}/$id/auto-renew',
      );
      return ProviderSubscriptionModel.fromJson(
          response.data as Map<String, dynamic>);
    });
  }

  /// Check if the current user has an active subscription with a given provider.
  Future<bool> hasActiveSubscription(String providerId) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.subscriptions}/check/$providerId',
      );
      return response.data['hasSubscription'] as bool? ?? false;
    });
  }

  // ─── Provider management ────────────────────────────────────────────────

  /// Get the provider's subscribers list (provider portal).
  Future<List<ProviderSubscriptionModel>> getMySubscribers({String? status}) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.providerSubscribers,
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      final raw = response.data is List
          ? response.data
          : (response.data['subscriptions'] ?? response.data['data'] ?? []);
      return (raw as List)
          .map((j) => ProviderSubscriptionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }

  /// Deduct one session from a session-based subscription (provider action).
  Future<ProviderSubscriptionModel> useSession(String subscriptionId) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.subscriptions}/$subscriptionId/use-session',
      );
      final subJson = response.data['subscription'] ?? response.data;
      return ProviderSubscriptionModel.fromJson(subJson as Map<String, dynamic>);
    });
  }
}
