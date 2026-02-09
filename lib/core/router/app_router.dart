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
        builder: (context, state) => const UserPortal(),
      ),
      GoRoute(
        path: '/pet-owner',
        builder: (context, state) => const PetOwnerPortal(),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );

  /// Navigate to portal based on user role
  static String getPortalRoute(String role) {
    switch (role) {
      case 'PET_OWNER':
        return '/pet-owner';
      case 'SHOP_OWNER':
        return '/shop-owner';
      case 'VETERINARY':
      case 'GROOMER':
      case 'PET_WALKER':
      case 'PET_TRAINER':
        return '/provider';
      default:
        return '/user';
    }
  }
}
