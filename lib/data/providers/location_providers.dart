import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/location_service.dart';

/// Singleton LocationService provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(DioClient());
});

/// All districts (public)
final locationsProvider = FutureProvider.autoDispose<List<LocationModel>>((ref) async {
  final service = ref.read(locationServiceProvider);
  return service.getDistricts();
});

/// All provinces (public)
final provincesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final service = ref.read(locationServiceProvider);
  return service.getProvinces();
});
