import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_providers.dart';

class PetOwnerProfilePage extends ConsumerWidget {
  const PetOwnerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: AppColors.secondary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Pet Owner Portal', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            // Menu Items
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _MenuItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
                  _MenuItem(icon: Icons.pets_outlined, label: 'My Pets', onTap: () {}),
                  _MenuItem(icon: Icons.shopping_bag_outlined, label: 'My Orders', onTap: () {}),
                  _MenuItem(icon: Icons.calendar_today_outlined, label: 'Appointments', onTap: () {}),
                  _MenuItem(icon: Icons.favorite_outline, label: 'Wishlist', onTap: () {}),
                  _MenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
                  _MenuItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
                  const SizedBox(height: 20),
                  _MenuItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    isDestructive: true,
                    onTap: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
        title: Text(label, style: TextStyle(color: isDestructive ? AppColors.error : AppColors.textPrimary, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: isDestructive ? AppColors.error : AppColors.textMuted),
      ),
    );
  }
}

