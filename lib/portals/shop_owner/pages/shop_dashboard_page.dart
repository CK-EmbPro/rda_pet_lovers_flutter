import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/order_detail_sheet.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/providers/shop_providers.dart';
import '../../../data/providers/product_providers.dart';
import '../../../data/providers/order_providers.dart';
import '../../../data/services/pet_service.dart';
import '../shop_owner_portal.dart';
import '../widgets/product_form_sheet.dart';


class ShopDashboardPage extends ConsumerWidget {
  const ShopDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myShopAsync = ref.watch(myShopProvider);
    
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
        child: myShopAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Error loading shop', style: AppTypography.h3),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(myShopProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (shop) {
             if (shop == null) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.store_mall_directory_outlined, size: 64, color: AppColors.textSecondary),
                     const SizedBox(height: 16),
                     const Text('You do not have a shop yet.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     Text('User ID: ${user?.id ?? "Unknown"}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                     const SizedBox(height: 24),
                     ElevatedButton(
                       onPressed: () {
                          // TODO: Implement Create Shop Flow
                          AppToast.info(context, 'Create Shop feature coming soon');
                       }, 
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppColors.primary,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                       ),
                       child: const Text('Create Shop'),
                     ),
                     const SizedBox(height: 16),
                     TextButton(
                        onPressed: () => ref.refresh(myShopProvider),
                        child: const Text('Refresh'),
                     ),
                   ],
                 ),
               );
             }

             // Fetch products and orders for stats
             final productsAsync = ref.watch(shopProductsProvider(shop.id));
             final ordersAsync = ref.watch(sellerOrdersProvider(null));
             final reportOrdersAsync = ref.watch(sellerReportOrdersProvider(50));

             return SingleChildScrollView(
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
                            Text(shop.name, style: AppTypography.h2),
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
                                  label: const Text('5'), // TODO: Real notification count
                                  child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Profile initials - circular, links to profile
                            GestureDetector(
                              onTap: () {
                                final portal = context.findAncestorStateOfType<ShopOwnerPortalState>();
                                portal?.navigateToTab(4); 
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
                                    getInitials(user?.fullName ?? shop.name),
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
                        productsAsync.when(
                           data: (p) => _StatCard(icon: Icons.inventory_2, value: '${p.data.length}', label: 'Products', color: AppColors.secondary),
                           loading: () => const Expanded(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))),
                           error: (_, _) => _StatCard(icon: Icons.inventory_2, value: '-', label: 'Products', color: AppColors.secondary),
                        ),
                        const SizedBox(width: 12),
                        ordersAsync.when(
                           data: (o) => _StatCard(icon: Icons.receipt_long, value: '${o.data.length}', label: 'Orders', color: Colors.orange),
                           loading: () => const Expanded(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))),
                           error: (_, _) => _StatCard(icon: Icons.receipt_long, value: '-', label: 'Orders', color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        // Revenue placeholder or calculation
                        ordersAsync.when(
                           data: (o) {
                             final revenue = o.data.fold<double>(0, (sum, order) => sum + order.totalAmount);
                             // Simple formatting
                             String valueArg = '${revenue.toInt()}'; // Default
                             if (revenue > 1000000) {
                               valueArg = '${(revenue/1000000).toStringAsFixed(1)}M';
                             } else if (revenue > 1000) {
                               valueArg = '${(revenue/1000).toStringAsFixed(1)}k';
                             }

                             return _StatCard(icon: Icons.monetization_on, value: valueArg, label: 'Revenue', color: AppColors.success);
                           },
                           loading: () => const Expanded(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))),
                           error: (_, _) => _StatCard(icon: Icons.monetization_on, value: '-', label: 'Revenue', color: AppColors.success),
                        ),
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
                                onTap: () => ProductFormSheet.show(context),
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
                  _buildQuickReportSection(context, reportOrdersAsync),
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
                  ordersAsync.when(
                    data: (paginated) {
                       final recent = paginated.data.take(3).toList();
                       if (recent.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20), child: Text("No recent orders"));
                       return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: recent.length,
                        itemBuilder: (context, index) {
                          return _RecentOrderCard(order: recent[index]);
                        },
                       );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox(),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildQuickReportSection(BuildContext context, AsyncValue<PaginatedResponse<OrderModel>> ordersAsync) {
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
            ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Unable to load sales data', style: TextStyle(color: AppColors.textSecondary)),
              data: (paginated) {
                final orders = paginated.data;
                // Filter for this month
                final now = DateTime.now();
                final thisMonthOrders = orders.where((o) => 
                  o.createdAt.year == now.year && o.createdAt.month == now.month
                ).toList();
                
                final monthlySales = thisMonthOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
                final fmt = NumberFormat.currency(symbol: '', decimalDigits: 0).format(monthlySales);

                // Calculate Top Selling Product (Simple aggregation)
                String topProductName = 'N/A';
                if (thisMonthOrders.isNotEmpty) {
                   final productCounts = <String, int>{};
                   for (var o in thisMonthOrders) {
                     for (var item in o.items) {
                       productCounts[item.productName] = (productCounts[item.productName] ?? 0) + item.quantity;
                     }
                   }
                   if (productCounts.isNotEmpty) {
                     final sortedEntries = productCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                     topProductName = sortedEntries.first.key;
                   }
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    fmt,
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  // Mock growth indicator for now as we don't have last month data easily without another query
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '↑',
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
                        SizedBox(
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
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.trending_up, color: AppColors.secondary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Top selling:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              Text(topProductName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
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
          color: color.withValues(alpha: 0.1),
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
  final OrderModel order;
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
                  // Use customer ID or placeholder until name is available
                  Text('Customer #${order.userId.substring(0, 4)}...', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${order.items.length} items • ${order.totalAmount.toInt()} RWF', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            _OrderStatusBadge(status: order.status),
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
    switch (status.toLowerCase()) {
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
        color: color.withValues(alpha: 0.1),
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
