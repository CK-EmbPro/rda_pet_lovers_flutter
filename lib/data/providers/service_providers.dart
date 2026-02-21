import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/pet_service.dart' show PaginatedResponse;
import '../services/service_api_service.dart';

/// Singleton provider for the ServiceApiService
final serviceApiServiceProvider = Provider<ServiceApiService>((ref) {
  return ServiceApiService(DioClient());
});

// ---------------------------------------------------------------------------
// Public providers
// ---------------------------------------------------------------------------

/// All available services (public, paginated)
final allServicesProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<ServiceModel>, ServiceQueryParams>(
        (ref, params) async {
  final api = ref.read(serviceApiServiceProvider);
  return api.getAll(
    page: params.page,
    limit: params.limit,
    categoryId: params.categoryId,
    paymentType: params.paymentType,
    search: params.search,
  );
});

/// Services by a given provider ID (public — for viewing another provider)
final providerServicesProvider = FutureProvider.autoDispose
    .family<List<ServiceModel>, String>((ref, providerId) async {
  final api = ref.read(serviceApiServiceProvider);
  return api.getByProvider(providerId);
});

/// All service categories from the services API (public — used in create/edit form picker)
/// Returns List<ServiceCategory> from the services module backend endpoint.
final serviceApiCategoriesProvider =
    FutureProvider.autoDispose<List<ServiceCategory>>((ref) async {
  final api = ref.read(serviceApiServiceProvider);
  return api.getCategories();
});

/// Single service detail (public)
final serviceDetailProvider =
    FutureProvider.autoDispose.family<ServiceModel, String>((ref, id) async {
  final api = ref.read(serviceApiServiceProvider);
  return api.getById(id);
});

// ---------------------------------------------------------------------------
// Protected providers (require auth)
// ---------------------------------------------------------------------------

/// The authenticated provider's own services
final myServicesProvider =
    FutureProvider.autoDispose<List<ServiceModel>>((ref) async {
  final api = ref.read(serviceApiServiceProvider);
  return api.getMyServices();
});

// ---------------------------------------------------------------------------
// CRUD state notifier
// ---------------------------------------------------------------------------

class ServiceCrudNotifier extends StateNotifier<AsyncValue<void>> {
  final ServiceApiService _api;

  ServiceCrudNotifier(this._api) : super(const AsyncValue.data(null));

  Future<ActionResponse<ServiceModel>> createService({
    required String name,
    required double basePrice,
    String? description,
    String paymentType = 'PAY_UPFRONT',
    double? priceYoungPet,
    double? priceOldPet,
    int? durationMinutes,
    String? categoryId,
    bool requiresSubscription = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.create(
        name: name,
        basePrice: basePrice,
        description: description,
        paymentType: paymentType,
        priceYoungPet: priceYoungPet,
        priceOldPet: priceOldPet,
        durationMinutes: durationMinutes,
        categoryId: categoryId,
        requiresSubscription: requiresSubscription,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return ActionResponse.error(e.toString());
    }
  }

  /// [updates] must contain only valid backend DTO keys (e.g. paymentType, basePrice).
  Future<ActionResponse<ServiceModel>> updateService(
      String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.update(id, updates);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return ActionResponse.error(e.toString());
    }
  }

  Future<ActionResponse<void>> deleteService(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.delete(id);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return ActionResponse.error(e.toString());
    }
  }

  Future<ActionResponse<ServiceModel>> toggleAvailability(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.toggleAvailability(id);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return ActionResponse.error(e.toString());
    }
  }
}

final serviceCrudProvider =
    StateNotifierProvider<ServiceCrudNotifier, AsyncValue<void>>((ref) {
  return ServiceCrudNotifier(ref.read(serviceApiServiceProvider));
});

// ---------------------------------------------------------------------------
// Query params helper
// ---------------------------------------------------------------------------

class ServiceQueryParams {
  final int page;
  final int limit;
  final String? categoryId;
  final String? paymentType;
  final String? search;

  const ServiceQueryParams({
    this.page = 1,
    this.limit = 10,
    this.categoryId,
    this.paymentType,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceQueryParams &&
          page == other.page &&
          limit == other.limit &&
          categoryId == other.categoryId &&
          paymentType == other.paymentType &&
          search == other.search;

  @override
  int get hashCode =>
      Object.hash(page, limit, categoryId, paymentType, search);
}
