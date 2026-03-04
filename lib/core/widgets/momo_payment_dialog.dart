import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/providers/order_providers.dart';
import '../../data/providers/payment_providers.dart';

/// A reusable MoMo payment status dialog that shows real-time payment progress.
///
/// Used by:
/// - Checkout flow (PaymentMethodPage)
/// - "Pay Now" action on OrderDetailSheet for PENDING orders
///
/// [onSuccess] is called when payment completes successfully so the caller
/// can clear state, navigate, or refresh data.
/// [onRetry] is called when the user taps "Try Again" so the caller can
/// re-trigger the payment without duplicating orders.
class MomoPaymentStatusDialog extends ConsumerWidget {
  /// Called after the user taps "Done" on a successful payment.
  final VoidCallback? onSuccess;

  /// Called when the user taps "Try Again" after a failure.
  final VoidCallback? onRetry;

  /// Called when the user taps "Close" / "Done" on dismiss.
  final VoidCallback? onDismiss;

  const MomoPaymentStatusDialog({
    super.key,
    this.onSuccess,
    this.onRetry,
    this.onDismiss,
  });

  /// Show as a modal dialog.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MomoPaymentStatusDialog(
        onSuccess: onSuccess,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

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
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),

          // Poll counter (subtle)
          if (paymentState.phase == MomoPaymentPhase.polling ||
              paymentState.phase == MomoPaymentPhase.waitingForUser)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Attempt ${paymentState.pollAttempts}/${MomoPaymentNotifier.maxPollAttempts}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ),

          const SizedBox(height: 32),

          // ── Success actions ──
          if (paymentState.phase == MomoPaymentPhase.success)
            PrimaryButton(
              label: 'Done',
              onPressed: () {
                ref.read(momoPaymentProvider.notifier).reset();
                ref.invalidate(myOrdersProvider);
                ref.invalidate(sellerOrdersProvider);
                Navigator.of(context).pop();
                onSuccess?.call();
              },
            ),

          // ── Failure actions ──
          if (paymentState.phase == MomoPaymentPhase.failed)
            Column(
              children: [
                PrimaryButton(
                  label: 'Try Again',
                  onPressed: () {
                    ref.read(momoPaymentProvider.notifier).reset();
                    Navigator.of(context).pop();
                    onRetry?.call();
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(momoPaymentProvider.notifier).reset();
                    ref.invalidate(myOrdersProvider);
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  child: const Text('Close'),
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
            color: AppColors.secondary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.phone_android, size: 40, color: AppColors.secondary),
              Positioned(
                bottom: 8,
                right: 8,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                ),
              ),
            ],
          ),
        );
      case MomoPaymentPhase.success:
        return const Icon(Icons.check_circle,
            size: 80, color: AppColors.success);
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
        return state.message ?? 'Your payment has been confirmed!';
      case MomoPaymentPhase.failed:
        return state.errorMessage ?? 'Something went wrong. Please try again.';
      case MomoPaymentPhase.idle:
        return '';
    }
  }
}
