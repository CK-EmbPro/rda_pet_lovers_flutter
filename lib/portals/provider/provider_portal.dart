import 'package:flutter/material.dart';
import '../../core/widgets/common_widgets.dart';
import 'pages/provider_dashboard_page.dart';
import 'pages/my_services_page.dart';
import 'pages/appointments_page.dart';
import 'pages/provider_reports_page.dart';
import 'pages/provider_profile_page.dart';

class ProviderPortal extends StatefulWidget {
  const ProviderPortal({super.key});

  @override
  State<ProviderPortal> createState() => ProviderPortalState();
}

class ProviderPortalState extends State<ProviderPortal> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ProviderDashboardPage(),
    const MyServicesPage(),
    const AppointmentsPage(),
    const ProviderReportsPage(),
    const ProviderProfilePage(),
  ];

  // Changed "Dashboard" to "Home" as requested
  final List<FloatingNavItem> _navItems = const [
    FloatingNavItem(icon: Icons.home_outlined, label: 'Home'),
    FloatingNavItem(icon: Icons.design_services_outlined, label: 'Services'),
    FloatingNavItem(icon: Icons.calendar_today_outlined, label: 'Bookings'),
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
