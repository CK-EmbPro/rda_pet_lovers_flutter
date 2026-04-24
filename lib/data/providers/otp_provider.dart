import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'auth_providers.dart';

// ---------------------------------------------------------------------------
// OTP state — tracks loading / success / error for verify and resend calls.
// ---------------------------------------------------------------------------

enum OtpStatus { idle, loading, success, error }

class OtpState {
  final OtpStatus status;
  final String? errorMessage;

  const OtpState({
    this.status = OtpStatus.idle,
    this.errorMessage,
  });

  OtpState copyWith({OtpStatus? status, String? errorMessage}) {
    return OtpState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == OtpStatus.loading;
  bool get hasError => status == OtpStatus.error;
  bool get isSuccess => status == OtpStatus.success;
}

// ---------------------------------------------------------------------------
// OtpNotifier
// ---------------------------------------------------------------------------

class OtpNotifier extends StateNotifier<OtpState> {
  final AuthService _authService;

  OtpNotifier(this._authService) : super(const OtpState());

  /// Verify the 6-digit OTP for the given userId.
  /// Returns true on success, false on failure.
  Future<bool> verifyOtp(String userId, String otp) async {
    state = state.copyWith(status: OtpStatus.loading, errorMessage: null);
    try {
      await _authService.verifyOtp(userId, otp);
      state = state.copyWith(status: OtpStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: OtpStatus.error,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  /// Resend a fresh OTP to the registered email address.
  /// Returns true on success, false on failure.
  Future<bool> resendOtp(String userId) async {
    state = state.copyWith(status: OtpStatus.loading, errorMessage: null);
    try {
      await _authService.resendOtp(userId);
      state = state.copyWith(status: OtpStatus.idle);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: OtpStatus.error,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  void resetState() {
    state = const OtpState();
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    // Strip DioException wrapper for cleaner UX messages
    if (msg.contains('DioException') || msg.contains('Exception:')) {
      final idx = msg.indexOf(':');
      if (idx != -1 && idx < msg.length - 1) {
        return msg.substring(idx + 1).trim();
      }
    }
    return msg;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final otpProvider = StateNotifierProvider<OtpNotifier, OtpState>((ref) {
  final authService = ref.read(authServiceProvider);
  return OtpNotifier(authService);
});
