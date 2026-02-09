import 'package:flutter/material.dart';
import '../../core/widgets/common_widgets.dart';
import 'pages/shop_dashboard_page.dart';
import 'pages/products_page.dart';
import 'pages/orders_page.dart';
import 'pages/shop_reports_page.dart';
import 'pages/shop_profile_page.dart';

class ShopOwnerPortal extends StatefulWidget {
  const ShopOwnerPortal({super.key});

  @override
  State<ShopOwnerPortal> createState() => ShopOwnerPortalState();
}

class ShopOwnerPortalState extends State<ShopOwnerPortal> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ShopDashboardPage(),
    const ProductsPage(),
    const OrdersPage(),
    const ShopReportsPage(),
    const ShopProfilePage(),
  ];

  // Updated nav items with Reports tab
  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(icon: Icons.home_outlined, label: 'Home'),
    FloatingNavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
    FloatingNavItem(icon: Icons.receipt_long_outlined, label: 'Orders'),
    FloatingNavItem(icon: Icons.bar_chart_outlined, label: 'Reports'),
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
