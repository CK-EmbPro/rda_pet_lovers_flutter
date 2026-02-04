import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'pages/shop_dashboard_page.dart';
import 'pages/products_page.dart';
import 'pages/orders_page.dart';
import 'pages/shop_profile_page.dart';

class ShopOwnerPortal extends StatefulWidget {
  const ShopOwnerPortal({super.key});

  @override
  State<ShopOwnerPortal> createState() => _ShopOwnerPortalState();
}

class _ShopOwnerPortalState extends State<ShopOwnerPortal> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ShopDashboardPage(),
    const ProductsPage(),
    const OrdersPage(),
    const ShopProfilePage(),
  ];

  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    FloatingNavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
    FloatingNavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
    FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

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
