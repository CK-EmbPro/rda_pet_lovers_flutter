import '../../core/api/dio_client.dart';
import '../models/notification_model.dart';
import 'base_api_service.dart';

/// Notification API Service — fetches and manages notifications from the backend.
class NotificationService extends BaseApiService {
  NotificationService(super.client);

  /// Fetch all notifications for the current user (paginated)
  Future<List<NotificationModel>> getAll({int limit = 30, int offset = 0}) async {
    return safeApiCall(() async {
      final response = await dio.get(
        ApiEndpoints.notifications,
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      final List<dynamic> data = response.data is List
          ? response.data as List<dynamic>
          : (response.data['data'] as List<dynamic>?) ?? [];

      return data
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    return safeApiCall(() async {
      final response = await dio.get('${ApiEndpoints.notifications}/unread-count');
      return (response.data['count'] as int?) ?? 0;
    });
  }

  /// Mark a single notification as read
  Future<NotificationModel> markAsRead(String id) async {
    return safeApiCall(() async {
      final response = await dio.put('${ApiEndpoints.notifications}/$id/read');
      return NotificationModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    return safeApiCall(() async {
      await dio.put('${ApiEndpoints.notifications}/read-all');
    });
  }

  /// Delete a notification
  Future<void> delete(String id) async {
    return safeApiCall(() async {
      await dio.delete('${ApiEndpoints.notifications}/$id');
    });
  }
}
