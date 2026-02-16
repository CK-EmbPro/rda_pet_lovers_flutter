import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore_for_file: use_null_aware_elements
import '../../core/api/dio_client.dart';
import '../models/user_model.dart';


/// Authentication Repository
/// Handles all auth-related API calls
class AuthRepository {
  final DioClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._client);

  /// Login with email and password
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      // Store tokens
      await _storage.write(
        key: 'access_token',
        value: response.data['accessToken'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: response.data['refreshToken'],
      );

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register a new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          if (phone != null) 'phone': phone,
        },
      );

      // Store tokens
      await _storage.write(
        key: 'access_token',
        value: response.data['accessToken'],
      );
      await _storage.write(
        key: 'refresh_token',
        value: response.data['refreshToken'],
      );

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user profile
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.usersMe);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    try {
      await _client.dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore logout errors
    } finally {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  String _handleError(DioException e) {
    if (e.response?.data is Map) {
      return e.response?.data['message'] ?? 'An error occurred';
    }
    return e.message ?? 'Network error';
  }
}
