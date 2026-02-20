import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/order_detail_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/providers/order_providers.dart';
import '../../../data/models/models.dart';
import '../../../data/models/shop_model.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Pending', 'Processing', 'Shipped', 'Delivered'];
  final List<String> _statusKeys = ['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED'];

  @override
  Widget build(BuildContext context) {
    final status = _statusKeys[_selectedFilter];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Orders',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage customer orders',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 24),
                // Filter Section - Sliding Segmented Control style
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filters.length, (index) {
                        final isSelected = _selectedFilter == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            child: Text(
                              _filters[index],
                              style: TextStyle(
                                color: isSelected ? AppColors.secondary : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _OrderList(status: status),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final String status;

  const _OrderList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(sellerOrdersProvider(status)); 

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (paginated) {
        final orders = paginated.data;
        if (orders.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long, 
            title: 'No orders', 
            subtitle: 'No ${status.toLowerCase()} orders found'
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(sellerOrdersProvider(status).future),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          ),
        );
      },
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final success = await ref.read(orderActionProvider.notifier).updateStatus(widget.order.id, newStatus);
    if (!mounted) return;
    setState(() => _isUpdating = false);
    if (success) {
      AppToast.success(context, _getStatusSuccessMessage(newStatus));
      // Invalidate all seller orders tabs to reflect the change
      ref.invalidate(sellerOrdersProvider);
    } else {
      AppToast.error(context, 'Failed to update order status. Please try again.');
    }
  }

  String _getStatusSuccessMessage(String status) {
    switch (status) {
      case 'PROCESSING': return 'Order is now being processed! 🎉';
      case 'SHIPPED': return 'Order marked as shipped! 📦';
      default: return 'Order status updated successfully';
    }
  }

  OrderModel get order => widget.order;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return GestureDetector(
      onTap: () => OrderDetailSheet.show(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Status Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderCode}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Customer ID: ${order.userId}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${order.totalAmount.toInt()} RWF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} items',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAction(BuildContext context) {
    final status = order.status.toLowerCase();
    
    if (status == 'pending') {
      return ElevatedButton(
        onPressed: _isUpdating ? null : () => _updateStatus('PROCESSING'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isUpdating
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Process Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (status == 'processing') {
      return ElevatedButton(
        onPressed: _isUpdating ? null : () => _updateStatus('SHIPPED'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isUpdating
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Mark as Shipped', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            order.displayStatus.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () => OrderDetailSheet.show(context, order),
          child: const Text(
            'View Details',
            style: TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return AppColors.secondary;
      case 'SHIPPED':
        return Colors.blue;
      case 'DELIVERED':
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'PROCESSING':
        return Icons.sync;
      case 'SHIPPED':
        return Icons.local_shipping;
      case 'DELIVERED':
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(date.year, date.month, date.day);
    
    if (orderDate == today) return 'Today';
    if (orderDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}';
  }
}
