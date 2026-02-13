import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import portals (will be created)
import '../../portals/user/user_portal.dart';
import '../../portals/pet_owner/pet_owner_portal.dart';
import '../../portals/shop_owner/shop_owner_portal.dart';
import '../../portals/provider/provider_portal.dart';

// Import features
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../portals/common/pages/shop_details_page.dart';
import '../../portals/common/pages/service_details_page.dart';
import '../../portals/common/pages/pet_details_page.dart';
import '../../portals/common/pages/product_details_page.dart';
import '../../portals/user/pages/cart_page.dart';
import '../../portals/user/pages/checkout_page.dart';
import '../../portals/user/pages/payment_method_page.dart';
import '../../portals/user/pages/orders_page.dart';

/// App Router Configuration
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Splash/Auth Check
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Portal Routes
      GoRoute(
        path: '/user',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final index = tab == 'cart' ? 3 : 0;
          return UserPortal(initialIndex: index);
        },
      ),
      GoRoute(
        path: '/pet-owner',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final index = tab == 'cart' ? 4 : 0;
          return PetOwnerPortal(initialIndex: index);
        },
      ),
      GoRoute(
        path: '/shop-owner',
        builder: (context, state) => const ShopOwnerPortal(),
      ),
      GoRoute(
        path: '/provider',
        builder: (context, state) => const ProviderPortal(),
      ),
      GoRoute(
        path: '/shop-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ShopDetailsPage(shopId: id);
        },
      ),
      GoRoute(
        path: '/service-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ServiceDetailsPage(serviceId: id);
        },
      ),
      GoRoute(
        path: '/pet-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PetDetailsPage(petId: id);
        },
      ),
      GoRoute(
        path: '/product-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailsPage(productId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/payment-method',
        builder: (context, state) => const PaymentMethodPage(),
      ),
      GoRoute(
        path: '/user/orders',
        builder: (context, state) => const OrdersPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );

  /// Navigate to portal based on user role
  /// Navigate to portal based on user role (handles raw roles or normalized primaryRole)
  static String getPortalRoute(String role) {
    final r = role.toUpperCase();
    if (r == 'PET_OWNER' || role == 'pet_owner') return '/pet-owner';
    if (r == 'SHOP_OWNER' || role == 'shop_owner') return '/shop-owner';
    if (r == 'VETERINARY' || r == 'GROOMER' || r == 'PET_WALKER' || r == 'PET_TRAINER' || role == 'provider') return '/provider';
    if (r == 'ADMIN' || role == 'admin') return '/admin'; // If admin exists
    return '/user';
  }
}
