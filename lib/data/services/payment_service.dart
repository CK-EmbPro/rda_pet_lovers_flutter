import '../../core/api/dio_client.dart';
import 'base_api_service.dart';

/// Payment API Service — handles MTN MoMo payment flow.
///
/// Flow:
/// 1. [processPayment] → POST /payments/process → initiates MoMo USSD push
/// 2. [checkPaymentStatus] → GET /payments/:id/status → polls until COMPLETED/FAILED
/// 3. User confirms on their phone → MoMo webhook or poll confirms
class PaymentService extends BaseApiService {
  PaymentService(super.client);

  /// Initiate an MTN MoMo payment.
  ///
  /// Sends a Request-to-Pay USSD push to the payer's phone.
  /// Returns the payment record with status PENDING.
  /// The frontend should then poll [checkPaymentStatus] until finalized.
  Future<PaymentResult> processPayment({
    required String type,
    required double amount,
    required String phoneNumber,
    String? orderId,
    String? petListingId,
    String? appointmentId,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.payments}/process',
        data: {
          'type': type,
          'amount': amount,
          'paymentMethod': 'MTN_MOMO',
          'phoneNumber': phoneNumber,
          if (orderId != null) 'orderId': orderId,
          if (petListingId != null) 'petListingId': petListingId,
          if (appointmentId != null) 'appointmentId': appointmentId,
        },
      );
      return PaymentResult.fromJson(response.data);
    });
  }

  /// Poll the MoMo payment status.
  ///
  /// Call this every 3-5 seconds after [processPayment] until
  /// status is COMPLETED or FAILED.
  Future<PaymentStatusResult> checkPaymentStatus(String paymentId) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.payments}/$paymentId/status',
      );
      return PaymentStatusResult.fromJson(response.data);
    });
  }

  /// Get payment history for the current user.
  Future<List<dynamic>> getPaymentHistory({int page = 1, int limit = 10}) async {
    return safeApiCall(() async {
      final response = await dio.get(
        '${ApiEndpoints.payments}/history',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data['data'] ?? [];
    });
  }
}

/// Result from initiating a payment
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? message;
  final String? momoReferenceId;
  final String? status;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.message,
    this.momoReferenceId,
    this.status,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>?;
    return PaymentResult(
      success: json['success'] ?? false,
      paymentId: payment?['id'],
      message: json['message'],
      momoReferenceId: json['momoReferenceId'],
      status: payment?['status'],
    );
  }
}

/// Result from polling payment status
class PaymentStatusResult {
  final String status;
  final String? message;
  final Map<String, dynamic>? payment;

  PaymentStatusResult({
    required this.status,
    this.message,
    this.payment,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      status: json['status'] ?? 'PENDING',
      message: json['message'],
      payment: json['payment'] as Map<String, dynamic>?,
    );
  }

  bool get isPending => status == 'PENDING' || status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
}
