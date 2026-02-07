import 'package:flutter/material.dart';
import '../../core/widgets/common_widgets.dart';
import 'pages/home_page.dart';
import 'pages/services_page.dart';
import '../pet_owner/pages/marketplace_page.dart';
import 'pages/pets_page.dart';
import 'pages/profile_page.dart';
import 'pages/cart_page.dart';

class UserPortal extends StatefulWidget {
  const UserPortal({super.key});

  @override
  State<UserPortal> createState() => UserPortalState();
}

class UserPortalState extends State<UserPortal> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ServicesPage(),
    const MarketplacePage(),
    const PetsPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(icon: Icons.home_outlined, label: 'Home'),
    FloatingNavItem(icon: Icons.miscellaneous_services_outlined, label: 'Services'),
    FloatingNavItem(icon: Icons.store_outlined, label: 'Market'),
    FloatingNavItem(icon: Icons.pets_outlined, label: 'Pets'),
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
