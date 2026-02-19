import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/order_providers.dart';
import '../../data/models/shop_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

/// All Orders Sheet — shows user's real orders from the backend.
class AllOrdersSheet extends ConsumerWidget {
  const AllOrdersSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AllOrdersSheet(),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED': return AppColors.success;
      case 'SHIPPED':   return AppColors.secondary;
      case 'CONFIRMED':
      case 'PROCESSING': return const Color(0xFF9333EA);
      case 'PENDING':   return Colors.orange;
      case 'CANCELLED': return AppColors.error;
      default:          return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':  return Icons.check_circle;
      case 'SHIPPED':    return Icons.local_shipping;
      case 'CONFIRMED':
      case 'PROCESSING': return Icons.access_time_rounded;
      case 'PENDING':    return Icons.hourglass_empty;
      case 'CANCELLED':  return Icons.cancel;
      default:           return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider(null));

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Orders',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    ordersAsync.when(
                      data: (orders) => Text(
                        '${orders.length} order${orders.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load orders',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(myOrdersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (orders) => orders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.inputFill),
                        SizedBox(height: 16),
                        Text('No orders yet', style: TextStyle(color: AppColors.textMuted)),
                        SizedBox(height: 8),
                        Text(
                          'Start shopping to see your orders here',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final itemCount = order.items.length;
                      final firstItem = order.items.isNotEmpty ? order.items.first : null;
                      return _OrderCard(
                        order: order,
                        firstItem: firstItem,
                        itemCount: itemCount,
                        statusColor: _getStatusColor(order.status),
                        statusIcon: _getStatusIcon(order.status),
                        formatDate: _formatDate,
                        onCancel: order.status == 'PENDING'
                          ? () async {
                              final ok = await ref.read(orderActionProvider.notifier).cancelOrder(order.id);
                              if (context.mounted) {
                                if (ok) {
                                  AppToast.success(context, 'Order cancelled successfully');
                                  ref.invalidate(myOrdersProvider);
                                } else {
                                  AppToast.error(context, 'Failed to cancel order');
                                }
                              }
                            }
                          : null,
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final OrderItemModel? firstItem;
  final int itemCount;
  final Color statusColor;
  final IconData statusIcon;
  final String Function(DateTime) formatDate;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.order,
    required this.firstItem,
    required this.itemCount,
    required this.statusColor,
    required this.statusIcon,
    required this.formatDate,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputFill),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order code
                      Text(
                        '#${order.orderCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      // Items summary
                      Text(
                        firstItem != null
                          ? itemCount > 1
                            ? '${firstItem!.productName} + ${itemCount - 1} more'
                            : firstItem!.productName
                          : 'No items',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Date and Amount
                      Row(
                        children: [
                          Text(
                            formatDate(order.createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const Spacer(),
                          Text(
                            '${order.totalAmount.toInt()} RWF',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.displayStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cancel button (only for pending orders)
          if (onCancel != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel Order'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
