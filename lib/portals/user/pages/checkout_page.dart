import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/auth_providers.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Color(0xFF21314C), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF21314C)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Items Section
            _buildSectionHeader('Your Items'),
            const SizedBox(height: 12),
            ...cartItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildItemThumbnail(item),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${item.price.toInt()} frw', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),

            const SizedBox(height: 24),

            // Order Summary
            _buildSectionHeader('Order Summary'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Total Amount',
                    value: '${total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} RWF',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            PrimaryButton(
              label: 'Proceed to Payment',
              onPressed: () {
                final user = ref.read(currentUserProvider);
                // Guest Restriction Logic
                if (user == null || user.primaryRole == 'user') {
                  final hasPet = cartItems.any((item) => item.type == 'PET');
                  if (!hasPet) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Account Required'),
                        content: const Text('Guests cannot purchase products without a pet. Please sign in or add a pet to your cart to proceed.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (user == null) context.go('/login');
                            },
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  // If has pet, allow proceed (triggers role upgrade flow later)
                }
                context.push('/payment-method');
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF21314C)),
    );
  }

  Widget _buildItemThumbnail(CartItem item) {
    final url = resolveImageUrl(item.image);
    if (url.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: AppColors.inputFill,
        child: Icon(
          item.type == 'PET' ? Icons.pets : Icons.shopping_bag,
          size: 22,
          color: AppColors.textMuted,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: 50,
      height: 50,
      fit: BoxFit.fill,
      placeholder: (_, _) => Container(
        width: 50,
        height: 50,
        color: AppColors.inputFill,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, _, _) => Container(
        width: 50,
        height: 50,
        color: AppColors.inputFill,
        child: Icon(
          item.type == 'PET' ? Icons.pets : Icons.shopping_bag,
          size: 22,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? const Color(0xFF21314C) : AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppColors.secondary : const Color(0xFF21314C),
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 20 : 14,
          ),
        ),
      ],
    );
  }
}
