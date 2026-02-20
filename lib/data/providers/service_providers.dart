import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/pet_service.dart';
import '../services/service_api_service.dart';

/// Singleton ServiceApiService provider
final serviceApiServiceProvider = Provider<ServiceApiService>((ref) {
  return ServiceApiService(DioClient());
});

/// All services (public, paginated)
final allServicesProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<ServiceModel>, ServiceQueryParams>(
        (ref, params) async {
  final service = ref.read(serviceApiServiceProvider);
  return service.getAll(
    page: params.page,
    limit: params.limit,
    categoryId: params.categoryId,
    serviceType: params.serviceType,
    search: params.search,
  );
});

/// Services by provider (public — used for viewing another provider's services)
final providerServicesProvider = FutureProvider.autoDispose
    .family<List<ServiceModel>, String>((ref, providerId) async {
  final service = ref.read(serviceApiServiceProvider);
  return service.getByProvider(providerId);
});

/// My own services as a provider (authenticated — uses /services/my-services)
final myServicesProvider = FutureProvider.autoDispose<List<ServiceModel>>((ref) async {
  final service = ref.read(serviceApiServiceProvider);
  return service.getMyServices();
});

/// Single service detail
final serviceDetailProvider =
    FutureProvider.autoDispose.family<ServiceModel, String>((ref, id) async {
  final service = ref.read(serviceApiServiceProvider);
  return service.getById(id);
});

/// Service CRUD notifier
class ServiceCrudNotifier extends StateNotifier<AsyncValue<void>> {
  final ServiceApiService _service;

  ServiceCrudNotifier(this._service) : super(const AsyncValue.data(null));

  Future<ServiceModel?> createService({
    required String name,
    required double basePrice,
    String? description,
    double? priceYoungPet,
    double? priceOldPet,
    int? durationMinutes,
    String? categoryId,
    String? paymentType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.create(
        name: name,
        basePrice: basePrice,
        description: description,
        priceYoungPet: priceYoungPet,
        priceOldPet: priceOldPet,
        durationMinutes: durationMinutes,
        categoryId: categoryId,
        paymentType: paymentType,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<ServiceModel?> updateService(
      String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.update(id, updates);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteService(String id) async {
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

  Future<ServiceModel?> toggleAvailability(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.toggleAvailability(id);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final serviceCrudProvider =
    StateNotifierProvider<ServiceCrudNotifier, AsyncValue<void>>((ref) {
  return ServiceCrudNotifier(ref.read(serviceApiServiceProvider));
});

/// Query parameters for service listing
class ServiceQueryParams {
  final int page;
  final int limit;
  final String? categoryId;
  final String? serviceType;
  final String? search;

  const ServiceQueryParams({
    this.page = 1,
    this.limit = 10,
    this.categoryId,
    this.serviceType,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceQueryParams &&
          page == other.page &&
          limit == other.limit &&
          categoryId == other.categoryId &&
          serviceType == other.serviceType &&
          search == other.search;

  @override
  int get hashCode =>
      Object.hash(page, limit, categoryId, serviceType, search);
}
