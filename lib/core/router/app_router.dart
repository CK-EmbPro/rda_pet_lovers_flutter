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
