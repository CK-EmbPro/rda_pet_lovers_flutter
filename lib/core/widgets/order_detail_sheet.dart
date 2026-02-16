import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shop_model.dart'; // Import OrderModel
 // Import formatters if needed, or implement locally

/// A modal sheet that shows order details when an order card is clicked
class OrderDetailSheet extends StatelessWidget {
  final OrderModel order;

  const OrderDetailSheet({super.key, required this.order});

  static void show(BuildContext context, dynamic orderData) {
    // Support both Model and Map for backward compatibility during migration if needed,
    // but preferably enforce Model.
    // If orderData is Map, we might need to parse it or throw.
    // Given we control the calls, let's enforce Model.
    // However, if we must support legacy Maps from other parts... 
    // For now, let's assume strict Model usage as we are refactoring.
    final OrderModel orderModel = orderData is OrderModel 
        ? orderData 
        : OrderModel.fromJson(orderData); // Fallback if Map passed (assuming JSON structure matches)

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => OrderDetailSheet(order: orderModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header with status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Order Info
            _buildSection(
              icon: Icons.receipt_long,
              title: 'Order Information',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Order ID', order.id),
                  _buildInfoRow('Date', _formatDate(order.createdAt)),
                  _buildInfoRow('Items', '${order.items.length} items'),
                ],
              ),
            ),
            const Divider(height: 32),
            
            // Customer Info
            _buildSection(
              icon: Icons.person,
              title: 'Customer',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO: Fetch user name if not in OrderModel. OrderModel has userId.
                  // For now showing ID or "Customer".
                  _buildInfoRow('Customer ID', order.userId),
                  if (order.shippingAddress != null)
                     _buildInfoRow('Address', order.shippingAddress!),
                ],
              ),
            ),
            const Divider(height: 32),
            
            // Payment Info
            _buildSection(
              icon: Icons.payment,
              title: 'Payment',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Total Amount', '${order.totalAmount.toInt()} RWF'),
                  // Assuming paid if order exists or checking status
                  _buildInfoRow('Payment Status', order.paymentStatus ?? 'Pending'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Actions based on status
            _buildActionButtons(context, status),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    status = status.toLowerCase();
    if (status == 'pending') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context), // TODO: Implement Cancel via provider
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel Order', style: TextStyle(color: AppColors.error)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), // TODO: Implement Process via provider
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Process Order', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'processing') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mark as Shipped', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    } else if (status == 'shipped') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mark as Delivered', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSection({required IconData icon, required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return AppColors.secondary;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
