import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'interceptors/auth_interceptor.dart';

/// Singleton Dio HTTP client for API communication.
/// AuthInterceptor is automatically wired on creation.
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

    // Wire auth interceptor for JWT handling
    _dio.interceptors.add(AuthInterceptor(_dio));

    // Add logging in debug builds
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
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

/// API Endpoints configuration — all backend routes
class ApiEndpoints {
  static const String baseUrl = 'http://192.168.2.59:3001/api/v1';

  // ── Auth ──────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ── Users ─────────────────────────────────────
  static const String usersMe = '/users/me';
  static const String users = '/users';

  // ── Pets ──────────────────────────────────────
  static const String pets = '/pets';
  static const String myPets = '/pets/my-pets';
  static const String petSpecies = '/pets/species';
  static const String petBreeds = '/pets/breeds';
  // Usage: /pets/:id/list-for-sale, /pets/:id/list-for-donation

  // ── Pet Listings ──────────────────────────────
  static const String petListings = '/pet-listings';
  static const String petListingsForSale = '/pet-listings/for-sale';
  static const String petListingsForAdoption = '/pet-listings/for-adoption';
  static const String petListingsMyListings = '/pet-listings/my-listings';
  // Usage: /pet-listings/:id/purchase, /pet-listings/:id/adopt
  // Usage: /pet-listings/:id/approve

  // ── Shops ─────────────────────────────────────
  static const String shops = '/shops';
  static const String myShop = '/shops/my-shop';

  // ── Products ──────────────────────────────────
  static const String products = '/products';
  static const String productCategories = '/products/categories';
  // Usage: /products/shop/:shopId, /products/:id/stock

  // ── Categories ────────────────────────────────
  // Deprecated: static const String productCategories = '/categories/products';
  // Deprecated: static const String serviceCategories = '/categories/services';

  // ── Services ──────────────────────────────────
  static const String services = '/services';
  static const String serviceCategories = '/services/categories';
  // Usage: /services/provider/:providerId, /services/:id/availability

  // ── Cart ──────────────────────────────────────
  static const String cart = '/cart';
  // Usage: /cart/items, /cart/items/:itemId, /cart/clear

  // ── Orders ────────────────────────────────────
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static const String sellerOrders = '/orders/seller-orders';
  // Usage: /orders/:id/status, /orders/:id/cancel, /orders/:id/tracking

  // ── Appointments ──────────────────────────────
  static const String appointments = '/appointments';
  static const String myAppointments = '/appointments/my-appointments';
  static const String providerAppointments = '/appointments/provider-appointments';
  // Usage: /appointments/:id/accept, /appointments/:id/reject
  // Usage: /appointments/:id/complete, /appointments/:id/cancel
  // Usage: /appointments/:id/reschedule

  // ── Vaccinations ──────────────────────────────
  static const String vaccinations = '/vaccinations';
  // Usage: /vaccinations/:id/administer

  // ── Payments ──────────────────────────────────
  static const String payments = '/payments';

  // ── Notifications ─────────────────────────────
  static const String notifications = '/notifications';

  // ── Locations ─────────────────────────────────
  static const String locations = '/locations';
  static const String districts = '/locations/districts';
  static const String provinces = '/locations/provinces';
}
