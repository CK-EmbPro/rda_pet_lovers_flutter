import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/pet_service.dart';
import 'base_api_service.dart';

/// Appointment API Service — handles appointment lifecycle.
/// All endpoints are protected.
class AppointmentService extends BaseApiService {
  AppointmentService(super.client);

  /// Get all appointments (admin)
  Future<PaginatedResponse<AppointmentModel>> getAll({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.appointments,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => AppointmentModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get my appointments as pet owner (protected)
  Future<PaginatedResponse<AppointmentModel>> getMyAppointments({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.myAppointments,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => AppointmentModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get provider appointments (protected)
  Future<PaginatedResponse<AppointmentModel>> getProviderAppointments({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.providerAppointments,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );

      final List<dynamic> rawData = response.data['data'] ?? [];
      final meta = response.data['meta'] ?? {};

      return PaginatedResponse(
        data: rawData.map((json) => AppointmentModel.fromJson(json)).toList(),
        page: meta['page'] ?? page,
        limit: meta['limit'] ?? limit,
        total: meta['total'] ?? 0,
        totalPages: meta['totalPages'] ?? 0,
      );
    });
  }

  /// Get appointment by ID (protected)
  Future<AppointmentModel> getById(String id) async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.appointments}/$id');
      return AppointmentModel.fromJson(response.data);
    });
  }

  /// Create appointment — uses separate scheduledDate + scheduledTime per backend DTO
  Future<AppointmentModel> create({
    required String serviceId,
    required String providerId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? petId,
    String? customerNotes,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        ApiEndpoints.appointments,
        data: {
          'serviceId': serviceId,
          'providerId': providerId,
          'scheduledDate': scheduledDate.toIso8601String(),
          'scheduledTime': scheduledTime,
          if (petId != null) 'petId': petId,
          if (customerNotes != null) 'customerNotes': customerNotes,
        },
      );
      return AppointmentModel.fromJson(response.data);
    });
  }

  /// Accept appointment (protected — provider)
  Future<AppointmentModel> accept(String id, {String? providerNotes}) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.appointments}/$id/accept',
        data: {if (providerNotes != null) 'providerNotes': providerNotes},
      );
      return AppointmentModel.fromJson(response.data);
    });
  }

  /// Reject appointment (protected — provider)
  Future<AppointmentModel> reject(String id, {String? reason}) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.appointments}/$id/reject',
        data: {if (reason != null) 'reason': reason},
      );
      return AppointmentModel.fromJson(response.data);
    });
  }

  /// Complete appointment (protected — provider)
  Future<AppointmentModel> complete(String id) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.appointments}/$id/complete',
      );
      return AppointmentModel.fromJson(response.data);
    });
  }

  /// Cancel appointment (protected)
  Future<AppointmentModel> cancel(String id, {String? reason}) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.appointments}/$id/cancel',
        data: {if (reason != null) 'reason': reason},
      );
      return AppointmentModel.fromJson(response.data);
    });
  }

  /// Reschedule appointment (protected)
  Future<AppointmentModel> reschedule(
    String id, {
    required DateTime newDate,
    required String newTime,
  }) async {
    return safeApiCall(() async {
      final response = await dio.patch(
        '${ApiEndpoints.appointments}/$id/reschedule',
        data: {
          'scheduledDate': newDate.toIso8601String(),
          'scheduledTime': newTime,
        },
      );
      return AppointmentModel.fromJson(response.data);
    });
  }
}
