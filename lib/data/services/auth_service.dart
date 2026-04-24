import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ignore_for_file: use_null_aware_elements
import '../../core/api/dio_client.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  final FlutterSecureStorage _storage;

  AuthService(super.client) : _storage = const FlutterSecureStorage();

  /// Login with email and password.
  ///
  /// Throws [UnverifiedAccountException] when the backend returns HTTP 403
  /// with `needsVerification: true` — this carries the `userId` so the caller
  /// can redirect directly to the OTP verification screen.
  ///
  /// All other errors are surfaced as human-readable [String]s via
  /// [BaseApiService.handleError], consistent with every other service.
  Future<UserModel> login(String email, String password) async {
    try {
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

      return user;
    } on DioException catch (e) {
      // 403 with needsVerification flag — account exists but OTP not confirmed.
      // Throw a typed exception so the UI can redirect to /verify-otp instead
      // of showing a generic error toast.
      final responseData = e.response?.data;
      if (e.response?.statusCode == 403 &&
          responseData is Map<String, dynamic> &&
          responseData['needsVerification'] == true) {
        final userId = responseData['userId']?.toString() ?? '';
        final message = responseData['message']?.toString() ??
            'Please verify your account first';
        throw UnverifiedAccountException(userId: userId, message: message);
      }

      // All other Dio errors → convert to a readable string (same as safeApiCall).
      throw handleError(e);
    } catch (e) {
      // Re-throw UnverifiedAccountException without wrapping.
      if (e is UnverifiedAccountException) rethrow;
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  /// Register a new user.
  /// Backend returns { userId, message } — no tokens and no full user object on register.
  /// Returns the userId so the caller can route to OTP verification.
  /// [pet] is an optional map included in the request body when the role is PET_OWNER.
  Future<String> register({
    required String fullName,
    required String email,
    required String password,
    required String role, // 'PET_OWNER', 'VETERINARY', etc.
    String? phone,
    Map<String, dynamic>? pet,
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
          if (pet != null) 'pet': pet,
        },
      );

      final data = response.data;
      // Backend contract: { userId: string, message: string }
      final userId = data['userId']?.toString() ?? '';
      if (userId.isEmpty) {
        throw Exception('Registration failed: no userId returned from server.');
      }
      return userId;
    });
  }

  /// Verify account with the 6-digit OTP sent to the user's email.
  /// Backend contract: POST /auth/verify-otp  body: { userId, otp }
  /// Returns { message: "Account verified successfully" }
  Future<void> verifyOtp(String userId, String otp) async {
    return safeApiCall(() async {
      await dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'userId': userId,
          'otp': otp,
        },
      );
    });
  }

  /// Resend a fresh OTP to the user's registered email.
  /// Backend contract: POST /auth/resend-otp  body: { userId }
  /// Returns { message: "OTP sent successfully" }
  Future<void> resendOtp(String userId) async {
    return safeApiCall(() async {
      await dio.post(
        ApiEndpoints.resendOtp,
        data: {'userId': userId},
      );
    });
  }

  /// Send forgot-password email (backend stores reset token in Redis)
  Future<void> forgotPassword(String email) async {
    return safeApiCall(() async {
      await dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    });
  }

  /// Reset password using the token received via email.
  /// Backend contract: POST /auth/reset-password  body: { token, password }
  Future<void> resetPassword(String token, String password) async {
    return safeApiCall(() async {
      await dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token,
          'password': password,
        },
      );
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
