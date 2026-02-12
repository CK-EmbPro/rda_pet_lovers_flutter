import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'pet_providers.dart';

/// All pet species (public)
final speciesProvider = FutureProvider.autoDispose<List<SpeciesModel>>((ref) async {
  final service = ref.read(petServiceProvider);
  return service.getSpecies();
});

/// Species details by ID (shortcut)
final speciesDetailProvider = Provider.family<AsyncValue<SpeciesModel>, String>((ref, id) {
  return ref.watch(speciesProvider).whenData(
    (list) => list.firstWhere((s) => s.id == id, orElse: () => SpeciesModel(id: id, name: 'Unknown')),
  );
});

/// Breeds for a specific species
final breedsProvider = FutureProvider.autoDispose.family<List<BreedModel>, String>((ref, speciesId) async {
  final service = ref.read(petServiceProvider);
  return service.getBreeds(speciesId: speciesId);
});

/// All breeds flat list for filtering
final allBreedsProvider = FutureProvider.autoDispose<List<BreedModel>>((ref) async {
  final service = ref.read(petServiceProvider);
  return service.getBreeds();
});
