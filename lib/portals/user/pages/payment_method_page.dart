import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/momo_payment_dialog.dart';
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

  /// Tracks already-created PENDING orders so "Try Again" can re-pay them
  /// without creating duplicates.  Cleared on success.
  List<MapEntry<String, double>>? _pendingOrderPayments;

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
                gradient: const LinearGradient(
                  colors: [Color(0xFF21314C), Color(0xFF2D4A7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF21314C).withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.15),
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
                suffixIcon: const Icon(Icons.edit_outlined,
                    color: AppColors.secondary, size: 20),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.secondary, width: 2)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.4))),
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
                color: AppColors.secondary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You will receive an MTN MoMo USSD prompt on your phone to confirm the payment.',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 13),
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

    final momoNotifier = ref.read(momoPaymentProvider.notifier);

    // If we already have PENDING orders from a previous attempt, skip order
    // creation and jump straight to payment.  This prevents duplicate orders
    // when the user taps "Try Again" after a failed MoMo payment.
    if (_pendingOrderPayments != null && _pendingOrderPayments!.isNotEmpty) {
      await momoNotifier.payForOrderQueue(
        orderPayments: _pendingOrderPayments!,
        phoneNumber: phone,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        _showMomoPaymentModal();
      }
      return;
    }

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
    bool allSuccess = true;
    final List<String> errors = [];

    // Track orderId → per-shop amount
    final List<MapEntry<String, double>> orderPayments = [];

    // 2. Create orders first (they start as PENDING)
    for (final shopId in itemsByShop.keys) {
      final items = itemsByShop[shopId]!;
      final orderItems = items
          .map((item) => ({
                'productId': item.id,
                'quantity': item.quantity,
              }))
          .toList();

      // Calculate per-shop subtotal (not total cart!)
      final shopSubtotal = items.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      final order = await notifier.createOrder(
        shopId: shopId,
        items: orderItems,
        notes: 'Paid via MTN MoMo ($phone)',
      );

      if (order != null) {
        orderPayments.add(MapEntry(order.id, shopSubtotal));
      } else {
        allSuccess = false;
        errors.add('Failed to create order for shop $shopId');
      }
    }

    if (!allSuccess || orderPayments.isEmpty) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ToastService.error(
            context, 'Failed to create orders: ${errors.join(', ')}');
      }
      return;
    }

    // Stash the order payments so retry will re-pay these orders
    _pendingOrderPayments = orderPayments;

    // 3. Initiate MoMo payment(s) using the payment queue.
    await momoNotifier.payForOrderQueue(
      orderPayments: orderPayments,
      phoneNumber: phone,
    );

    if (mounted) {
      setState(() => _isProcessing = false);

      // 4. Show payment status modal with polling
      _showMomoPaymentModal();
    }
  }

  void _showMomoPaymentModal() {
    MomoPaymentStatusDialog.show(
      context,
      onSuccess: () {
        ref.read(cartProvider.notifier).clear();
        _pendingOrderPayments = null;
        context.go('/user');
      },
      onRetry: () {
        // "Try Again" — re-trigger payment for already-created orders
        _processPaymentAndOrder();
      },
      onDismiss: () {
        // User chooses to go home without retrying
        _pendingOrderPayments = null;
        context.go('/user');
      },
    );
  }
}
