import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../providers/auth_providers.dart';
import '../services/pet_listing_service.dart';


/// Singleton PetListingService provider
final petListingServiceProvider = Provider<PetListingService>((ref) {
  return PetListingService(DioClient());
});

/// For-sale pet listings (public)
final forSaleListingsProvider =
    FutureProvider.autoDispose<List<PetListingModel>>((ref) async {
  // Watch current user so we re-fetch when login state changes (for own-pet exclusion)
  ref.watch(currentUserProvider);
  
  final service = ref.read(petListingServiceProvider);
  final result = await service.getForSale(limit: 50);
  return result.data;
});

/// For-adoption pet listings (public)
final forAdoptionListingsProvider =
    FutureProvider.autoDispose<List<PetListingModel>>((ref) async {
  // Watch current user so we re-fetch when login state changes (for own-pet exclusion)
  ref.watch(currentUserProvider);
  
  final service = ref.read(petListingServiceProvider);
  final result = await service.getForAdoption(limit: 50);
  return result.data;
});

/// My listings (protected)
final myListingsProvider =
    FutureProvider.autoDispose<List<PetListingModel>>((ref) async {
  final service = ref.read(petListingServiceProvider);
  final result = await service.getMyListings(limit: 50);
  return result.data;
});

/// Listing action notifier
class ListingActionNotifier extends StateNotifier<AsyncValue<void>> {
  final PetListingService _service;

  ListingActionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> purchase(String listingId) async {
    state = const AsyncValue.loading();
    try {
      await _service.purchase(listingId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> adopt(String listingId) async {
    state = const AsyncValue.loading();
    try {
      await _service.adopt(listingId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final listingActionProvider =
    StateNotifierProvider<ListingActionNotifier, AsyncValue<void>>((ref) {
  return ListingActionNotifier(ref.read(petListingServiceProvider));
});
