import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Order model for display
class OrderItem {
  final String id;
  final String productName;
  final String shopName;
  final double totalAmount;
  final String status; // pending, shipped, delivered, cancelled
  final DateTime createdAt;
  final String? productImage;
  final int quantity;

  OrderItem({
    required this.id,
    required this.productName,
    required this.shopName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.productImage,
    this.quantity = 1,
  });
}

/// Mock orders data
final List<OrderItem> mockOrders = [
  OrderItem(
    id: 'order-1',
    productName: 'Premium Dog Food',
    shopName: 'Pet Paradise',
    totalAmount: 45000,
    status: 'delivered',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    quantity: 2,
  ),
  OrderItem(
    id: 'order-2',
    productName: 'Cat Treats Pack',
    shopName: 'Happy Paws',
    totalAmount: 12000,
    status: 'shipped',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    quantity: 1,
  ),
  OrderItem(
    id: 'order-3',
    productName: 'Pet Shampoo',
    shopName: 'Pet Care Plus',
    totalAmount: 8500,
    status: 'pending',
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    quantity: 1,
  ),
  OrderItem(
    id: 'order-4',
    productName: 'Dog Collar - Large',
    shopName: 'Pawfect Bites',
    totalAmount: 15000,
    status: 'delivered',
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    quantity: 1,
  ),
  OrderItem(
    id: 'order-5',
    productName: 'Cat Litter Box',
    shopName: 'Happy Paws',
    totalAmount: 35000,
    status: 'cancelled',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    quantity: 1,
  ),
];

/// All Orders Sheet - Opens like NotificationsSheet
class AllOrdersSheet extends StatelessWidget {
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
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
        return AppColors.secondary;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'pending':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                      'All Orders',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${mockOrders.length} orders',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
            child: mockOrders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.inputFill),
                        SizedBox(height: 16),
                        Text('No orders yet', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: mockOrders.length,
                    itemBuilder: (context, index) {
                      final order = mockOrders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.inputFill),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getStatusIcon(order.status),
                                color: _getStatusColor(order.status),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Name
                                  Text(
                                    order.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  // Shop and Quantity
                                  Row(
                                    children: [
                                      const Icon(Icons.store, size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        order.shopName,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Qty: ${order.quantity}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Date and Amount
                                  Row(
                                    children: [
                                      Text(
                                        _formatDate(order.createdAt),
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
                                color: _getStatusColor(order.status).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
