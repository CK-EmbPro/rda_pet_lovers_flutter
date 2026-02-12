import '../models/models.dart';
import 'base_api_service.dart';
import '../../core/api/dio_client.dart';

/// Location API Service — handles fetching districts and provinces.
class LocationService extends BaseApiService {
  LocationService(super.client);

  /// Get all districts (public)
  Future<List<LocationModel>> getDistricts({String? provinceName}) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.districts,
        queryParameters: {if (provinceName != null) 'provinceName': provinceName},
      );
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((item) {
        if (item is String) {
          // Backend returns plain district name strings
          return LocationModel(id: item, name: item, district: item);
        }
        return LocationModel.fromJson(item as Map<String, dynamic>);
      }).toList();
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
