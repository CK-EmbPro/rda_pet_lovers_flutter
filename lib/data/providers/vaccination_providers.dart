import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../services/vaccination_service.dart';

/// Singleton VaccinationService provider
final vaccinationServiceProvider = Provider<VaccinationService>((ref) {
  return VaccinationService(DioClient());
});

/// All vaccination types (catalog)
final vaccinationCatalogProvider =
    FutureProvider.autoDispose<List<VaccinationModel>>((ref) async {
  final service = ref.read(vaccinationServiceProvider);
  return service.getAll();
});

/// Vaccination action notifier
class VaccinationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final VaccinationService _service;

  VaccinationActionNotifier(this._service)
      : super(const AsyncValue.data(null));

  Future<PetVaccinationModel?> administer({
    required String vaccinationId,
    required String petId,
    String? batchNumber,
    String? notes,
    DateTime? nextDueDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final record = await _service.administer(
        vaccinationId: vaccinationId,
        petId: petId,
        batchNumber: batchNumber,
        notes: notes,
        nextDueDate: nextDueDate,
      );
      state = const AsyncValue.data(null);
      return record;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final vaccinationActionProvider =
    StateNotifierProvider<VaccinationActionNotifier, AsyncValue<void>>((ref) {
  return VaccinationActionNotifier(ref.read(vaccinationServiceProvider));
});
