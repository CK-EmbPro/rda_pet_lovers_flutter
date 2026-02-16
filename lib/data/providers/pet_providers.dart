import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/pet_service.dart';

/// Singleton PetService provider
final petServiceProvider = Provider<PetService>((ref) {
  return PetService(DioClient());
});

/// All pets (public, paginated) — auto-refreshable
final allPetsProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<PetModel>, PetQueryParams>((ref, params) async {
  final service = ref.read(petServiceProvider);
  return service.getAll(
    page: params.page,
    limit: params.limit,
    speciesId: params.speciesId,
    breedId: params.breedId,
    gender: params.gender,
    search: params.search,
  );
});

/// My pets (protected) — current user's pets
final myPetsProvider = FutureProvider.autoDispose<List<PetModel>>((ref) async {
  final service = ref.read(petServiceProvider);
  final result = await service.getMyPets(limit: 50);
  return result.data;
});

/// Single pet detail (public)
final petDetailProvider =
    FutureProvider.autoDispose.family<PetModel, String>((ref, id) async {
  final service = ref.read(petServiceProvider);
  return service.getById(id);
});

/// Pet CRUD state notifier for create/update/delete operations
class PetCrudNotifier extends StateNotifier<AsyncValue<void>> {
  final PetService _service;

  PetCrudNotifier(this._service) : super(const AsyncValue.data(null));

  Future<String> generatePetCode() async {
    return _service.generatePetCode();
  }

  Future<PetModel?> createPet({
    required String name,
    required String speciesId,
    required String gender,
    String? breedId,
    double? weightKg,
    int? ageYears,
    String? birthDate,
    String? locationId,
    String? nationality,
    List<String>? images,
    List<String>? videos,
    String? description,
    String? healthSummary,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? vaccinations,
    String? petCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final pet = await _service.create(
        name: name,
        speciesId: speciesId,
        gender: gender,
        petCode: petCode,
        breedId: breedId,
        weightKg: weightKg,
        ageYears: ageYears,
        birthDate: birthDate,
        locationId: locationId,
        nationality: nationality,
        images: images,
        videos: videos,
        description: description,
        healthSummary: healthSummary,
        metadata: metadata,
        vaccinations: vaccinations,
      );
      state = const AsyncValue.data(null);
      return pet;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<PetModel?> updatePet(String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final pet = await _service.update(id, updates);
      state = const AsyncValue.data(null);
      return pet;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deletePet(String id) async {
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

  Future<bool> listForSale(String petId, {required double price, String? description}) async {
    state = const AsyncValue.loading();
    try {
      await _service.listForSale(petId, price: price, description: description);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> listForDonation(String petId, {String? description}) async {
    state = const AsyncValue.loading();
    try {
      await _service.listForDonation(petId, description: description);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelListing(String petId) async {
    state = const AsyncValue.loading();
    try {
      await _service.cancelListing(petId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final petCrudProvider =
    StateNotifierProvider<PetCrudNotifier, AsyncValue<void>>((ref) {
  return PetCrudNotifier(ref.read(petServiceProvider));
});

/// Query parameters container for pet listing
class PetQueryParams {
  final int page;
  final int limit;
  final String? speciesId;
  final String? breedId;
  final String? gender;
  final String? search;

  const PetQueryParams({
    this.page = 1,
    this.limit = 10,
    this.speciesId,
    this.breedId,
    this.gender,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetQueryParams &&
          page == other.page &&
          limit == other.limit &&
          speciesId == other.speciesId &&
          breedId == other.breedId &&
          gender == other.gender &&
          search == other.search;

  @override
  int get hashCode => Object.hash(page, limit, speciesId, breedId, gender, search);
}
