import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'pages/dashboard_page.dart';
import 'pages/my_pets_page.dart';
import 'pages/marketplace_page.dart';
import 'pages/profile_page.dart';

class PetOwnerPortal extends StatefulWidget {
  const PetOwnerPortal({super.key});

  @override
  State<PetOwnerPortal> createState() => _PetOwnerPortalState();
}

class _PetOwnerPortalState extends State<PetOwnerPortal> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const MyPetsPage(),
    const MarketplacePage(),
    const PetOwnerProfilePage(),
  ];

  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    FloatingNavItem(icon: Icons.pets_outlined, label: 'My Pets'),
    FloatingNavItem(icon: Icons.store_outlined, label: 'Market'),
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
