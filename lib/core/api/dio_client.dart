import 'package:dio/dio.dart';

/// Singleton Dio HTTP client for API communication
class DioClient {
  static DioClient? _instance;
  late final Dio _dio;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  factory DioClient() {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
}

/// API Endpoints configuration
class ApiEndpoints {
  static const String baseUrl = 'http://localhost:3001/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String usersMe = '/users/me';
  static const String users = '/users';

  // Pets
  static const String pets = '/pets';
  static const String petListings = '/pet-listings';

  // Shops
  static const String shops = '/shops';
  static const String products = '/products';

  // Orders
  static const String orders = '/orders';
  static const String cart = '/cart';

  // Appointments
  static const String appointments = '/appointments';
  static const String services = '/services';

  // Payments
  static const String payments = '/payments';

  // Notifications
  static const String notifications = '/notifications';
}
