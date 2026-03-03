import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/payment_status_modal.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/order_providers.dart';
import '../../../data/providers/payment_providers.dart';

class PaymentMethodPage extends ConsumerStatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _phoneInitialized = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-fill phone from user profile on first build
    if (!_phoneInitialized) {
      final user = ref.read(currentUserProvider);
      if (user?.phone != null && user!.phone!.isNotEmpty) {
        String phone = user.phone!;
        // Strip +250 prefix if present so field shows local format
        if (phone.startsWith('+250')) phone = '0${phone.substring(4)}';
        if (phone.startsWith('250')) phone = '0${phone.substring(3)}';
        _phoneController.text = phone;
      }
      _phoneInitialized = true;
    }

    final cartItems = ref.watch(cartProvider);
    final total = cartItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MTN MoMo Payment',
            style: TextStyle(color: Color(0xFF21314C), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF21314C)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── MTN MoMo Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade700, Colors.amber.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MTN Mobile Money',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Pay securely with MoMo',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Phone Number Input ──
            const Text('MTN Phone Number',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
              decoration: InputDecoration(
                hintText: '078 XXX XXXX',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('\u{1F1F7}\u{1F1FC}',
                          style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text('+250',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300),
                    ],
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 32),

            // ── Payment Summary ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(height: 24),
                  _summaryRow(
                      'Items (${cartItems.length})',
                      '${total.toStringAsFixed(0)} RWF'),
                  const Divider(height: 24),
                  _summaryRow(
                    'Total',
                    '${total.toStringAsFixed(0)} RWF',
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Info Note ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will receive an MTN MoMo USSD prompt on your phone to confirm the payment.',
                      style: TextStyle(
                          color: Colors.amber.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            PrimaryButton(
              label: _isProcessing
                  ? 'Processing…'
                  : 'Pay ${total.toStringAsFixed(0)} RWF',
              onPressed: _isProcessing ? null : _processPaymentAndOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isBold ? const Color(0xFF21314C) : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 16 : 14)),
        Text(value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBold ? AppColors.secondary : const Color(0xFF21314C),
                fontSize: isBold ? 16 : 14)),
      ],
    );
  }

  Future<void> _processPaymentAndOrder() async {
    // Validate MTN number
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ToastService.error(context, 'Please enter your MTN MoMo number');
      return;
    }
    final mtnRegex = RegExp(r'^(078|079)\d{7}$');
    if (!mtnRegex.hasMatch(phone)) {
      ToastService.error(context,
          'Enter a valid MTN number (078 or 079, 10 digits)');
      return;
    }

    setState(() => _isProcessing = true);

    // 1. Create orders grouped by shop
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      if (mounted) {
        ToastService.error(context, 'Cart is empty');
        setState(() => _isProcessing = false);
      }
      return;
    }

    final Map<String, List<CartItem>> itemsByShop = {};
    for (final item in cartItems) {
      itemsByShop.putIfAbsent(item.shopId, () => []).add(item);
    }

    final notifier = ref.read(orderActionProvider.notifier);
    final momoNotifier = ref.read(momoPaymentProvider.notifier);
    bool allSuccess = true;
    final List<String> errors = [];
    final List<String> createdOrderIds = [];

    // 2. Create orders first (they start as PENDING)
    for (final shopId in itemsByShop.keys) {
      final items = itemsByShop[shopId]!;
      final orderItems = items
          .map((item) => ({
                'productId': item.id,
                'quantity': item.quantity,
                'price': item.price,
                'type': item.type,
              }))
          .toList();

      final order = await notifier.createOrder(
        shopId: shopId,
        items: orderItems,
        notes: 'Paid via MTN MoMo ($phone)',
      );

      if (order != null) {
        createdOrderIds.add(order.id);
      } else {
        allSuccess = false;
        errors.add('Failed to create order for shop $shopId');
      }
    }

    if (!allSuccess || createdOrderIds.isEmpty) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ToastService.error(
            context, 'Failed to create orders: ${errors.join(', ')}');
      }
      return;
    }

    // 3. Initiate MoMo payment for each order
    //    For simplicity, process orders sequentially
    //    Each order triggers a separate USSD push
    for (final orderId in createdOrderIds) {
      // Calculate the order total from cart items
      final orderShop = itemsByShop.entries
          .firstWhere((e) => true); // will iterate through all
      
      await momoNotifier.payForOrder(
        orderId: orderId,
        amount: cartItems.fold<double>(
            0, (sum, item) => sum + (item.price * item.quantity)),
        phoneNumber: phone,
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);

      // 4. Show payment status modal with polling
      _showMomoPaymentModal();
    }
  }

  void _showMomoPaymentModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _MomoPaymentStatusDialog(),
    );
  }
}

/// Dialog that shows real-time MoMo payment status with polling.
///
/// Displays different states:
/// - Initiating: spinner + "Sending payment request..."
/// - Waiting for user: phone icon + "Confirm on your phone"
/// - Polling: spinner + "Checking payment status..."
/// - Success: checkmark + "Payment successful!"
/// - Failed: error icon + reason
class _MomoPaymentStatusDialog extends ConsumerWidget {
  const _MomoPaymentStatusDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(momoPaymentProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),

          // Icon / Animation
          _buildIcon(paymentState),

          const SizedBox(height: 24),

          // Title
          Text(
            _getTitle(paymentState),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Message
          Text(
            _getMessage(paymentState),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),

          // Poll counter (subtle)
          if (paymentState.phase == MomoPaymentPhase.polling ||
              paymentState.phase == MomoPaymentPhase.waitingForUser)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Attempt ${paymentState.pollAttempts}/${MomoPaymentNotifier.maxPollAttempts}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(height: 32),

          // Action button (only show when finalized)
          if (paymentState.phase == MomoPaymentPhase.success)
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                ref.read(momoPaymentProvider.notifier).reset();
                Navigator.of(context).pop();
                context.go('/user');
              },
            ),

          if (paymentState.phase == MomoPaymentPhase.failed)
            Column(
              children: [
                PrimaryButton(
                  label: 'Try Again',
                  onPressed: () {
                    ref.read(momoPaymentProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(momoPaymentProvider.notifier).reset();
                    Navigator.of(context).pop();
                    context.go('/user');
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildIcon(MomoPaymentState state) {
    switch (state.phase) {
      case MomoPaymentPhase.initiating:
      case MomoPaymentPhase.polling:
        return const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      case MomoPaymentPhase.waitingForUser:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.phone_android, size: 40, color: Colors.amber.shade700),
              Positioned(
                bottom: 8,
                right: 8,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber.shade700),
                  ),
                ),
              ),
            ],
          ),
        );
      case MomoPaymentPhase.success:
        return const Icon(Icons.check_circle, size: 80, color: AppColors.success);
      case MomoPaymentPhase.failed:
        return const Icon(Icons.error_outline, size: 80, color: AppColors.error);
      case MomoPaymentPhase.idle:
        return const SizedBox.shrink();
    }
  }

  String _getTitle(MomoPaymentState state) {
    switch (state.phase) {
      case MomoPaymentPhase.initiating:
        return 'Sending Payment Request';
      case MomoPaymentPhase.waitingForUser:
        return 'Confirm on Your Phone';
      case MomoPaymentPhase.polling:
        return 'Processing Payment';
      case MomoPaymentPhase.success:
        return 'Payment Successful!';
      case MomoPaymentPhase.failed:
        return 'Payment Failed';
      case MomoPaymentPhase.idle:
        return '';
    }
  }

  String _getMessage(MomoPaymentState state) {
    switch (state.phase) {
      case MomoPaymentPhase.initiating:
        return 'Connecting to MTN MoMo...';
      case MomoPaymentPhase.waitingForUser:
        return 'A USSD prompt has been sent to your phone.\nPlease dial *182# or check your notifications to approve the payment.';
      case MomoPaymentPhase.polling:
        return 'Waiting for payment confirmation from MTN MoMo...';
      case MomoPaymentPhase.success:
        return state.message ?? 'Your order has been placed successfully!';
      case MomoPaymentPhase.failed:
        return state.errorMessage ?? 'Something went wrong. Please try again.';
      case MomoPaymentPhase.idle:
        return '';
    }
  }
}
