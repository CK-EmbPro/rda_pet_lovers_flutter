import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/order_detail_sheet.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';
import '../shop_owner_portal.dart';
import 'products_page.dart';

// Mock orders for dashboard
final List<Map<String, dynamic>> _mockRecentOrders = [
  {'id': 'ORD-001', 'customer': 'John Doe', 'items': 3, 'total': 45000, 'status': 'pending', 'date': 'Today'},
  {'id': 'ORD-002', 'customer': 'Jane Smith', 'items': 1, 'total': 25000, 'status': 'shipped', 'date': 'Today'},
  {'id': 'ORD-003', 'customer': 'Mike Wilson', 'items': 5, 'total': 80000, 'status': 'delivered', 'date': 'Yesterday'},
];

class ShopDashboardPage extends ConsumerWidget {
  const ShopDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final shopName = 'Pet Paradise'; // Would come from shop data
    
    // Get user initials
    String getInitials(String? name) {
      if (name == null || name.isEmpty) return 'SO';
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back,', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text(shopName, style: AppTypography.h2),
                      ],
                    ),
                    Row(
                      children: [
                        // Notification icon
                        GestureDetector(
                          onTap: () => NotificationsSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Badge(
                              label: const Text('5'),
                              child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile initials - circular, links to profile
                        GestureDetector(
                          onTap: () {
                            final portal = context.findAncestorStateOfType<ShopOwnerPortalState>();
                            portal?.navigateToTab(4); // Profile tab (will be index 4 after adding Reports)
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                getInitials(user?.fullName ?? shopName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _StatCard(icon: Icons.inventory_2, value: '48', label: 'Products', color: AppColors.secondary),
                    const SizedBox(width: 12),
                    _StatCard(icon: Icons.receipt_long, value: '156', label: 'Orders', color: Colors.orange),
                    const SizedBox(width: 12),
                    _StatCard(icon: Icons.monetization_on, value: '2.5M', label: 'Revenue', color: AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Actions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.add,
                            label: 'Add Product',
                            color: AppColors.secondary,
                            onTap: () => _showAddProductSheet(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.inventory,
                            label: 'Manage Stock',
                            color: Colors.orange,
                            onTap: () {
                              final portal = context.findAncestorStateOfType<ShopOwnerPortalState>();
                              portal?.navigateToTab(1); // Products tab
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Report Section
              _buildQuickReportSection(context),
              const SizedBox(height: 24),
              
              // Recent Orders
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {
                        final portal = context.findAncestorStateOfType<ShopOwnerPortalState>();
                        portal?.navigateToTab(2); // Orders tab
                      },
                      child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _mockRecentOrders.length,
                itemBuilder: (context, index) {
                  final order = _mockRecentOrders[index];
                  return _RecentOrderCard(order: order);
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReportSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sales Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('This Month', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '14,254',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '1.5% ↑',
                              style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Total Sales (RWF)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                // Mini chart placeholder
                Container(
                  width: 80,
                  height: 40,
                  child: CustomPaint(
                    painter: _MiniChartPainter(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Top selling product
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Top selling:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('Premium Dog Food', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // View full report button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final portal = context.findAncestorStateOfType<ShopOwnerPortalState>();
                  portal?.navigateToTab(3); // Reports tab
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Full Report', style: TextStyle(color: AppColors.secondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add New Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const AppTextField(label: 'Product Name', hint: 'e.g: Premium Dog Food', prefixIcon: Icons.inventory_2),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: AppTextField(label: 'Price (RWF)', hint: '25000', prefixIcon: Icons.monetization_on)),
                SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Stock', hint: '50', prefixIcon: Icons.inventory)),
              ],
            ),
            const SizedBox(height: 16),
            const AppTextField(label: 'Description', hint: 'Describe your product...', prefixIcon: Icons.description),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Add Product', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// Recent Order Card
class _RecentOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _RecentOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => OrderDetailSheet.show(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['customer'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${order['items']} items • ${order['total']} RWF', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            _OrderStatusBadge(status: order['status'] as String),
          ],
        ),
      ),
    );
  }
}

// Order Status Badge
class _OrderStatusBadge extends StatelessWidget {
  final String status;
  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'processing':
        color = AppColors.secondary;
        break;
      case 'shipped':
        color = Colors.blue;
        break;
      case 'delivered':
        color = AppColors.success;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Mini Chart Painter
class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
