import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../services/payment_service.dart';

/// Singleton PaymentService provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(DioClient());
});

/// State for the MoMo payment flow
enum MomoPaymentPhase {
  idle,
  initiating,     // Sending request to backend
  waitingForUser, // USSD prompt sent, waiting for user to confirm on phone
  polling,        // Polling for status
  success,        // Payment confirmed
  failed,         // Payment failed or timed out
}

class MomoPaymentState {
  final MomoPaymentPhase phase;
  final String? paymentId;
  final String? message;
  final String? errorMessage;
  final int pollAttempts;

  const MomoPaymentState({
    this.phase = MomoPaymentPhase.idle,
    this.paymentId,
    this.message,
    this.errorMessage,
    this.pollAttempts = 0,
  });

  MomoPaymentState copyWith({
    MomoPaymentPhase? phase,
    String? paymentId,
    String? message,
    String? errorMessage,
    int? pollAttempts,
  }) {
    return MomoPaymentState(
      phase: phase ?? this.phase,
      paymentId: paymentId ?? this.paymentId,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
      pollAttempts: pollAttempts ?? this.pollAttempts,
    );
  }

  bool get isProcessing =>
      phase == MomoPaymentPhase.initiating ||
      phase == MomoPaymentPhase.waitingForUser ||
      phase == MomoPaymentPhase.polling;
}

/// Notifier that manages the full MoMo payment lifecycle:
/// 1. Initiate payment (sends USSD push)
/// 2. Poll for status every 5 seconds
/// 3. Resolve with success or failure
class MomoPaymentNotifier extends StateNotifier<MomoPaymentState> {
  final PaymentService _paymentService;
  Timer? _pollTimer;

  /// Max number of poll attempts (24 * 5s = 2 minutes)
  static const int maxPollAttempts = 24;

  /// Poll interval in seconds
  static const int pollIntervalSeconds = 5;

  MomoPaymentNotifier(this._paymentService)
      : super(const MomoPaymentState());

  /// Start a payment for a product order.
  Future<void> payForOrder({
    required String orderId,
    required double amount,
    required String phoneNumber,
  }) async {
    await _initiatePayment(
      type: 'order',
      amount: amount,
      phoneNumber: phoneNumber,
      orderId: orderId,
    );
  }

  /// Start a payment for a pet purchase.
  Future<void> payForPet({
    required String petListingId,
    required double amount,
    required String phoneNumber,
  }) async {
    await _initiatePayment(
      type: 'pet_purchase',
      amount: amount,
      phoneNumber: phoneNumber,
      petListingId: petListingId,
    );
  }

  /// Start a payment for an appointment.
  Future<void> payForAppointment({
    required String appointmentId,
    required double amount,
    required String phoneNumber,
  }) async {
    await _initiatePayment(
      type: 'appointment',
      amount: amount,
      phoneNumber: phoneNumber,
      appointmentId: appointmentId,
    );
  }

  Future<void> _initiatePayment({
    required String type,
    required double amount,
    required String phoneNumber,
    String? orderId,
    String? petListingId,
    String? appointmentId,
  }) async {
    // Cancel any existing polling
    _stopPolling();

    state = const MomoPaymentState(
      phase: MomoPaymentPhase.initiating,
      message: 'Initiating payment...',
    );

    try {
      final result = await _paymentService.processPayment(
        type: type,
        amount: amount,
        phoneNumber: phoneNumber,
        orderId: orderId,
        petListingId: petListingId,
        appointmentId: appointmentId,
      );

      if (result.success && result.paymentId != null) {
        state = MomoPaymentState(
          phase: MomoPaymentPhase.waitingForUser,
          paymentId: result.paymentId,
          message: 'Please confirm the MoMo prompt on your phone...',
        );

        // Start polling after a short delay to give user time to see the prompt
        _startPolling(result.paymentId!);
      } else {
        state = MomoPaymentState(
          phase: MomoPaymentPhase.failed,
          errorMessage: result.message ?? 'Failed to initiate payment',
        );
      }
    } catch (e) {
      state = MomoPaymentState(
        phase: MomoPaymentPhase.failed,
        errorMessage: e.toString(),
      );
    }
  }

  void _startPolling(String paymentId) {
    _pollTimer = Timer.periodic(
      const Duration(seconds: pollIntervalSeconds),
      (_) => _pollStatus(paymentId),
    );
  }

  Future<void> _pollStatus(String paymentId) async {
    final currentAttempts = state.pollAttempts + 1;

    if (currentAttempts > maxPollAttempts) {
      _stopPolling();
      state = MomoPaymentState(
        phase: MomoPaymentPhase.failed,
        paymentId: paymentId,
        errorMessage: 'Payment timed out. If money was deducted, please contact support.',
      );
      return;
    }

    state = state.copyWith(
      phase: MomoPaymentPhase.polling,
      pollAttempts: currentAttempts,
      message: 'Checking payment status...',
    );

    try {
      final status = await _paymentService.checkPaymentStatus(paymentId);

      if (status.isCompleted) {
        _stopPolling();
        state = MomoPaymentState(
          phase: MomoPaymentPhase.success,
          paymentId: paymentId,
          message: status.message ?? 'Payment successful!',
        );
      } else if (status.isFailed) {
        _stopPolling();
        state = MomoPaymentState(
          phase: MomoPaymentPhase.failed,
          paymentId: paymentId,
          errorMessage: status.message ?? 'Payment was declined',
        );
      }
      // If still PENDING, keep polling (state stays as-is with updated attempts)
    } catch (e) {
      // Don't stop polling on network errors, just log and retry
      state = state.copyWith(
        message: 'Checking payment status...',
      );
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Reset to idle state
  void reset() {
    _stopPolling();
    state = const MomoPaymentState();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

/// Provider for the MoMo payment flow
final momoPaymentProvider =
    StateNotifierProvider.autoDispose<MomoPaymentNotifier, MomoPaymentState>(
  (ref) {
    final service = ref.read(paymentServiceProvider);
    return MomoPaymentNotifier(service);
  },
);
