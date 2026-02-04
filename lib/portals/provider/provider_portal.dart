import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'pages/provider_dashboard_page.dart';
import 'pages/my_services_page.dart';
import 'pages/appointments_page.dart';
import 'pages/provider_profile_page.dart';

class ProviderPortal extends StatefulWidget {
  const ProviderPortal({super.key});

  @override
  State<ProviderPortal> createState() => _ProviderPortalState();
}

class _ProviderPortalState extends State<ProviderPortal> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ProviderDashboardPage(),
    const MyServicesPage(),
    const AppointmentsPage(),
    const ProviderProfilePage(),
  ];

  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    FloatingNavItem(icon: Icons.design_services_outlined, label: 'Services'),
    FloatingNavItem(icon: Icons.calendar_today_outlined, label: 'Bookings'),
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
