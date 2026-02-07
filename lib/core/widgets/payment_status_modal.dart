import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../data/providers/cart_provider.dart';
import 'common_widgets.dart';

class PaymentStatusModal extends ConsumerWidget {
  final bool isSuccess;
  final String? message;

  const PaymentStatusModal({
    super.key,
    required this.isSuccess,
    this.message,
  });

  static void show(BuildContext context, {required bool isSuccess, String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentStatusModal(isSuccess: isSuccess, message: message),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            size: 80,
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 24),
          Text(
            isSuccess ? 'Payment Successful!' : 'Payment Failed',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? (isSuccess 
                ? 'Your order has been placed successfully. You will receive a notification shortly.' 
                : 'There was an issue processing your payment. Please try again.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: isSuccess ? 'Back to Home' : 'Try Again',
            onPressed: () {
              if (isSuccess) {
                ref.read(cartProvider.notifier).clear();
                context.go('/user');
              } else {
                context.pop();
              }
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
