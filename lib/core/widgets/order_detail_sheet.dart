import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/momo_payment_dialog.dart';
import '../../data/models/shop_model.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/order_providers.dart';
import '../../data/providers/payment_providers.dart';

/// A modal sheet that shows order details when an order card is clicked.
/// Supports cancel action for PENDING orders (buyer).
class OrderDetailSheet extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailSheet({super.key, required this.order});

  static void show(BuildContext context, dynamic orderData) {
    final OrderModel orderModel = orderData is OrderModel
        ? orderData
        : OrderModel.fromJson(orderData);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) =>
            OrderDetailSheet(order: orderModel),
      ),
    );
  }

  @override
  ConsumerState<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<OrderDetailSheet> {
  bool _isCancelling = false;
  bool _isPayingNow = false;

  OrderModel get order => widget.order;

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Cancel Order',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel order #${order.orderCode}?',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text('Reason (optional)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 2,
              minLines: 1,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Changed my mind',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Keep Order',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel Order',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final reason = reasonController.text.trim();
    reasonController.dispose();

    setState(() => _isCancelling = true);
    final success = await ref
        .read(orderActionProvider.notifier)
        .cancelOrder(order.id, reason: reason.isEmpty ? null : reason);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success) {
      AppToast.success(context, 'Order cancelled successfully');
      ref.invalidate(myOrdersProvider);
      ref.invalidate(sellerOrdersProvider);
      if (mounted) Navigator.pop(context);
    } else {
      AppToast.error(context, 'Failed to cancel order. Please try again.');
    }
  }

  /// Show a dialog to collect MoMo phone number and initiate payment
  /// for this PENDING order using the existing payment infrastructure.
  Future<void> _payNow() async {
    // Pre-fill from user profile
    final user = ref.read(currentUserProvider);
    String initialPhone = '';
    if (user?.phone != null && user!.phone!.isNotEmpty) {
      String p = user.phone!;
      if (p.startsWith('+250')) p = '0${p.substring(4)}';
      if (p.startsWith('250')) p = '0${p.substring(3)}';
      initialPhone = p;
    }

    final phoneController = TextEditingController(text: initialPhone);

    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet,
                  color: AppColors.secondary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Pay with MoMo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your MTN MoMo number to pay ${order.totalAmount.toInt()} RWF for order #${order.orderCode}.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text('MTN Phone Number',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 14, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: '078 XXX XXXX',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixText: '+250 ',
                prefixStyle: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final value = phoneController.text.trim();
                    if (value.isEmpty) return;
                    final mtnRegex = RegExp(r'^(078|079)\d{7}$');
                    if (!mtnRegex.hasMatch(value)) return;
                    Navigator.pop(ctx, value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Pay Now',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    phoneController.dispose();
    if (phone == null || !mounted) return;

    setState(() => _isPayingNow = true);

    // Use existing MomoPaymentNotifier.payForOrder
    final momoNotifier = ref.read(momoPaymentProvider.notifier);
    await momoNotifier.payForOrder(
      orderId: order.id,
      amount: order.totalAmount,
      phoneNumber: phone,
    );

    if (!mounted) return;
    setState(() => _isPayingNow = false);

    // Close this bottom sheet and show the shared payment status dialog
    Navigator.pop(context);

    if (!context.mounted) return;
    MomoPaymentStatusDialog.show(
      context,
      onSuccess: () {
        // Refresh order lists
        ref.invalidate(myOrdersProvider);
        ref.invalidate(sellerOrdersProvider);
      },
      onRetry: () {
        // Re-open this sheet so user can try again
        OrderDetailSheet.show(context, order);
      },
      onDismiss: () {
        ref.invalidate(myOrdersProvider);
      },
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
                  _buildInfoRow('Order Code', '#${order.orderCode}'),
                  _buildInfoRow('Date', _formatDate(order.createdAt)),
                  if (order.shopName != null)
                    _buildInfoRow('Shop', order.shopName!),
                  _buildInfoRow('Type', order.isPetOrder ? 'Pet Adoption' : 'Product Order'),
                ],
              ),
            ),
            const Divider(height: 32),

            // Order Items Breakdown
            _buildSection(
              icon: Icons.inventory_2_outlined,
              title: 'Items (${order.items.length})',
              content: Column(
                children: order.items.map((item) => _buildItemRow(item)).toList(),
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
                  _buildInfoRow('Name', order.buyerName ?? 'Unknown'),
                  if (order.buyerPhone != null)
                    _buildInfoRow('Phone', order.buyerPhone!),
                ],
              ),
            ),
            const Divider(height: 32),
            
            // Payment Info
            _buildSection(
              icon: Icons.payment,
              title: 'Payment Summary',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Subtotal', '${order.subtotal.toInt()} RWF'),
                  if (order.discount != null && order.discount! > 0)
                    _buildInfoRow('Discount', '-${order.discount!.toInt()} RWF'),
                  _buildInfoRow('Total', '${order.totalAmount.toInt()} RWF'),
                  _buildInfoRow('Status', order.paymentId != null ? 'Paid' : 'Pending'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cancellation reason for cancelled orders
            if (order.status.toUpperCase() == 'CANCELLED' &&
                order.cancellationReason != null &&
                order.cancellationReason!.isNotEmpty)
              _buildSection(
                icon: Icons.info_outline,
                title: 'Cancellation Reason',
                content: Text(
                  order.cancellationReason!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            if (order.status.toUpperCase() == 'CANCELLED')
              const SizedBox(height: 8),

            // Pay Now button for PENDING orders (no payment yet)
            if (order.status.toUpperCase() == 'PENDING' && order.paymentId == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isPayingNow || _isCancelling) ? null : _payNow,
                    icon: _isPayingNow
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.account_balance_wallet, size: 18),
                    label: Text(
                        _isPayingNow
                            ? 'Initiating...'
                            : 'Pay ${order.totalAmount.toInt()} RWF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

            // Cancel button for PENDING orders
            if (order.status.toUpperCase() == 'PENDING')
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isCancelling ? null : _cancelOrder,
                    icon: _isCancelling
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.error),
                          )
                        : const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(
                        _isCancelling ? 'Cancelling...' : 'Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Item image
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
              image: hasImage
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                          resolveImageUrl(item.imageUrl)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : Icon(
                    item.petListingId != null ? Icons.pets : Icons.inventory_2,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
          ),
          const SizedBox(width: 10),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item.quantity} × ${item.unitPrice.toInt()} RWF',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Item total
          Text(
            '${item.totalPrice.toInt()} RWF',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.secondary;
      case 'processing':
        return AppColors.secondary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
