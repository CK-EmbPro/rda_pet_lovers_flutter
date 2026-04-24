import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/subscription_service.dart';

/// Singleton SubscriptionService
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(DioClient());
});

// ─── Plan browsing ──────────────────────────────────────────────────────────

/// All plans for a specific provider.
final providerSubscriptionPlansProvider =
    FutureProvider.autoDispose.family<List<SubscriptionPlanModel>, String>(
  (ref, providerId) async {
    final service = ref.read(subscriptionServiceProvider);
    return service.getProviderModels(providerId);
  },
);

// ─── Pet owner ──────────────────────────────────────────────────────────────

/// All subscriptions for the logged-in pet owner.
final mySubscriptionsProvider =
    FutureProvider.autoDispose<List<ProviderSubscriptionModel>>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.getMySubscriptions();
});

/// Single subscription detail.
final subscriptionDetailProvider =
    FutureProvider.autoDispose.family<ProviderSubscriptionModel, String>(
  (ref, id) async {
    final service = ref.read(subscriptionServiceProvider);
    return service.getById(id);
  },
);

/// Check if the current user has an active subscription with a provider.
final hasSubscriptionProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, providerId) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.hasActiveSubscription(providerId);
});

// ─── Provider dashboard ─────────────────────────────────────────────────────

/// All subscribers for the logged-in provider.
final mySubscribersProvider =
    FutureProvider.autoDispose<List<ProviderSubscriptionModel>>((ref) async {
  final service = ref.read(subscriptionServiceProvider);
  return service.getMySubscribers();
});

// ─── Action notifier ────────────────────────────────────────────────────────

class SubscriptionActionNotifier extends StateNotifier<AsyncValue<void>> {
  final SubscriptionService _service;
  final Ref _ref;

  SubscriptionActionNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  /// Subscribe to a plan. Returns (subscription, errorMessage).
  Future<(ProviderSubscriptionModel?, String?)> subscribe({
    required String modelId,
    bool autoRenew = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final sub = await _service.subscribe(modelId: modelId, autoRenew: autoRenew);
      state = const AsyncValue.data(null);
      _ref.invalidate(mySubscriptionsProvider);
      return (sub, null);
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
      final dynamic msg = e.response?.data?['message'];
      final errorMsg = msg is String
          ? msg
          : (msg is List ? msg.join(', ') : 'Failed to subscribe');
      return (null, errorMsg);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return (null, e.toString());
    }
  }

  /// Cancel a subscription.
  Future<bool> cancel(String id, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.cancel(id, reason: reason);
      state = const AsyncValue.data(null);
      _ref.invalidate(mySubscriptionsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Toggle auto-renew.
  Future<bool> toggleAutoRenew(String id) async {
    state = const AsyncValue.loading();
    try {
      await _service.toggleAutoRenew(id);
      state = const AsyncValue.data(null);
      _ref.invalidate(mySubscriptionsProvider);
      _ref.invalidate(subscriptionDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Deduct a session (provider action).
  Future<(ProviderSubscriptionModel?, String?)> useSession(String subscriptionId) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _service.useSession(subscriptionId);
      state = const AsyncValue.data(null);
      _ref.invalidate(mySubscribersProvider);
      return (updated, null);
    } on DioException catch (e, st) {
      state = AsyncValue.error(e, st);
      final dynamic msg = e.response?.data?['message'];
      final errorMsg = msg is String ? msg : 'Failed to use session';
      return (null, errorMsg);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return (null, e.toString());
    }
  }
}

final subscriptionActionProvider =
    StateNotifierProvider<SubscriptionActionNotifier, AsyncValue<void>>((ref) {
  return SubscriptionActionNotifier(
    ref.read(subscriptionServiceProvider),
    ref,
  );
});
