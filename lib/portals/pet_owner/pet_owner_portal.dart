import 'package:flutter/material.dart';
import '../../core/widgets/common_widgets.dart';
import 'pages/dashboard_page.dart';
import 'pages/my_pets_page.dart';
import 'pages/marketplace_page.dart';
import '../../portals/user/pages/services_page.dart';
import 'pages/profile_page.dart';
import '../user/pages/cart_page.dart';

class PetOwnerPortal extends StatefulWidget {
  const PetOwnerPortal({super.key});

  @override
  State<PetOwnerPortal> createState() => PetOwnerPortalState();
}

class PetOwnerPortalState extends State<PetOwnerPortal> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ServicesPage(),
    const MarketplacePage(),
    const MyPetsPage(),
    const CartPage(),
    const PetOwnerProfilePage(),
  ];

  // Standardized order with User Portal
  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(icon: Icons.home_outlined, label: 'Home'),
    FloatingNavItem(icon: Icons.miscellaneous_services_outlined, label: 'Services'),
    FloatingNavItem(icon: Icons.store_outlined, label: 'Market'),
    FloatingNavItem(icon: Icons.pets_outlined, label: 'My Pets'),
    FloatingNavItem(icon: Icons.shopping_cart_outlined, label: 'Cart'),
    FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  void navigateToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
      ),
    );
  }
}
