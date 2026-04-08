
import 'base_api_service.dart';
import '../../core/api/dio_client.dart';
// ignore_for_file: use_null_aware_elements
import '../models/models.dart';

/// Location API Service — handles fetching districts and provinces.
class LocationService extends BaseApiService {
  LocationService(super.client);

  /// Get all districts (public) — uses /locations which returns full objects with real UUIDs
  Future<List<LocationModel>> getDistricts({String? provinceName}) async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.locations);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      final all = data
          .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
          .where((l) => l.id.isNotEmpty)
          .toList();
      if (provinceName != null) {
        return all.where((l) => l.province == provinceName).toList();
      }
      return all;
    });
  }

  /// Get all provinces (public)
  Future<List<String>> getProvinces() async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.provinces);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((e) => e.toString()).toList();
    });
  }
}
