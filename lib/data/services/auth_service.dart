import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ignore_for_file: use_null_aware_elements
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  final FlutterSecureStorage _storage;

  AuthService(super.client) : _storage = const FlutterSecureStorage();

  /// Login with email and password
  Future<UserModel> login(String email, String password) async {
    return safeApiCall(() async {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {
          'identifier': email,
          'password': password,
        },
      );

      final data = response.data;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final user = UserModel.fromJson(data['user']);

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      // Also save user info if needed, but we typically just re-fetch 'me' or keep in memory
      
      return user;
    });
  }

  /// Register a new user
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role, // 'PET_OWNER', 'SHOP_OWNER', 'VETERINARY', etc.
    String? phone,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
          if (phone != null) 'phone': phone,
        },
      );

      final data = response.data;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final user = UserModel.fromJson(data['user']);

      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      return user;
    });
  }

  /// Logout (clear tokens and notify backend)
  Future<void> logout() async {
    try {
      // Notify backend if needed (optional based on backend implementation)
      // await dio.post(ApiEndpoints.logout); 
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  /// Get current user profile
  Future<UserModel> me() async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.usersMe);
      return UserModel.fromJson(response.data);
    });
  }

  /// Update current user profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return safeApiCall(() async {
      final response = await dio.put(ApiEndpoints.usersMe, data: data);
      return UserModel.fromJson(response.data);
    });
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword, String confirmNewPassword) async {
    return safeApiCall(() async {
      await dio.put('${ApiEndpoints.usersMe}/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });
    });
  }
  
  /// Check if user is logged in (has token)
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
