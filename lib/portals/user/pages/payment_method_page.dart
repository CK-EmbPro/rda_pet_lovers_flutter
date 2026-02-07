import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/payment_status_modal.dart';
import '../../../data/providers/cart_provider.dart';

class PaymentMethodPage extends ConsumerStatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  String _selectedMethod = 'MTN Momo';
  final TextEditingController _phoneController = TextEditingController(text: '0780000000');
  final TextEditingController _cardNumberController = TextEditingController();

  final List<Map<String, dynamic>> _methods = [
    {'name': 'MTN Momo', 'icon': Icons.account_balance_wallet, 'color': Colors.yellow.shade700},
    {'name': 'Airtel Money', 'icon': Icons.account_balance_wallet, 'color': Colors.red},
    {'name': 'Credit Card', 'icon': Icons.credit_card, 'color': Colors.blue},
    {'name': 'PayPal', 'icon': Icons.payment, 'color': Colors.indigo},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Method', style: TextStyle(color: Color(0xFF21314C), fontWeight: FontWeight.bold)),
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
            const Text(
              'Select how you want to pay',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Payment Methods Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: _methods.length,
              itemBuilder: (context, index) {
                final method = _methods[index];
                final isSelected = _selectedMethod == method['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMethod = method['name']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(method['icon'], color: method['color'], size: 32),
                        const SizedBox(height: 12),
                        Text(
                          method['name'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.secondary : const Color(0xFF21314C),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // Contextual Inputs
            if (_selectedMethod.contains('Momo') || _selectedMethod.contains('Money'))
              _buildPhoneInput()
            else if (_selectedMethod == 'Credit Card')
              _buildCardInput(),
              
            const SizedBox(height: 60),
            
            PrimaryButton(
              label: 'Pay Now',
              onPressed: () {
                // Simulate processing
                PaymentStatusModal.show(context, isSuccess: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter mobile money number',
            prefixIcon: const Icon(Icons.phone_android),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildCardInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Card Details', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Card Number',
            prefixIcon: const Icon(Icons.credit_card),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'MM/YY',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'CVV',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
