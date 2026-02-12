import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/providers/shop_providers.dart';
// import '../../../data/providers/product_providers.dart'; // Uncomment if fetching stats

class ShopProfilePage extends ConsumerWidget {
  const ShopProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myShopAsync = ref.watch(myShopProvider);

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
              child: myShopAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                data: (shop) {
                  if (shop == null) {
                    return Column(
                      children: [
                        const Icon(Icons.store, size: 50, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(user?.fullName ?? 'Shop Owner', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('No shop created yet', style: TextStyle(color: Colors.white70)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          image: shop.logoUrl != null 
                              ? DecorationImage(image: NetworkImage(shop.logoUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: shop.logoUrl == null 
                            ? const Icon(Icons.store, size: 50, color: AppColors.secondary)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(shop.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(shop.description ?? 'Premium Pet Supplies', 
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatItem(label: 'Rating', value: shop.rating.toString()),
                          const _StatItem(label: 'Products', value: '0'), 
                          const _StatItem(label: 'Orders', value: '0'),
                        ],
                      ),
                    ],
                  );
                }
              ),
            ),
            // Menu Items
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _MenuItem(icon: Icons.store_outlined, label: 'Shop Settings', onTap: () {
                    // Navigate to shop settings
                  }),
                  _MenuItem(icon: Icons.inventory_2_outlined, label: 'Products', onTap: () {
                     // Navigate to products tab (via portal controller if possible, or direct route)
                  }),
                  _MenuItem(icon: Icons.receipt_long_outlined, label: 'Orders', onTap: () {
                    // Navigate to orders
                  }),
                  _MenuItem(icon: Icons.monetization_on_outlined, label: 'Earnings', onTap: () {}),
                  _MenuItem(icon: Icons.local_shipping_outlined, label: 'Shipping Settings', onTap: () {}),
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
                    }
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
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
