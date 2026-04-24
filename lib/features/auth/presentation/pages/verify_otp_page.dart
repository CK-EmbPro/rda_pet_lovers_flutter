import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/utils/toast_service.dart';
import '../../../../data/providers/otp_provider.dart';

/// OTP Verification screen shown immediately after successful registration.
///
/// Route: /verify-otp?userId=<id>
///
/// Flow:
///   1. User lands here with their userId from the register response.
///   2. Enters the 6-digit code emailed to them.
///   3. On success → navigates to /login with a success toast.
///   4. On "Resend" tap (after 60 s cooldown) → calls POST /auth/resend-otp.
class VerifyOtpPage extends ConsumerStatefulWidget {
  final String userId;

  const VerifyOtpPage({super.key, required this.userId});

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  // ── OTP digit controllers & focus nodes ─────────────────────────────────
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  // ── Resend cooldown timer ────────────────────────────────────────────────
  static const int _cooldownSeconds = 60;
  int _remainingSeconds = _cooldownSeconds;
  Timer? _cooldownTimer;
  bool get _canResend => _remainingSeconds == 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Cooldown helpers ─────────────────────────────────────────────────────

  void _startCooldown() {
    setState(() => _remainingSeconds = _cooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  // ── OTP helpers ──────────────────────────────────────────────────────────

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  bool get _otpComplete => _otpValue.length == _otpLength;

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste: distribute digits across boxes
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      // Move focus to the last filled box or the next empty one
      final nextEmpty =
          _controllers.indexWhere((c) => c.text.isEmpty);
      if (nextEmpty != -1) {
        FocusScope.of(context).requestFocus(_focusNodes[nextEmpty]);
      } else {
        _focusNodes[_otpLength - 1].requestFocus();
      }
      if (_otpComplete) _handleVerify();
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }

    if (_otpComplete) _handleVerify();
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _handleVerify() async {
    final otp = _otpValue;
    if (otp.length < _otpLength) {
      ToastService.error(context, 'Please enter all 6 digits.');
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(otpProvider.notifier)
        .verifyOtp(widget.userId, otp);

    if (!mounted) return;

    if (success) {
      ToastService.success(
        context,
        'Account verified! Please log in to continue.',
      );
      ref.read(otpProvider.notifier).resetState();
      context.go('/login');
    } else {
      final errorMsg =
          ref.read(otpProvider).errorMessage ?? 'Verification failed.';
      ToastService.error(context, errorMsg);
      // Clear OTP boxes so user can re-enter
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final success = await ref
        .read(otpProvider.notifier)
        .resendOtp(widget.userId);

    if (!mounted) return;

    if (success) {
      ToastService.success(context, 'A new code has been sent to your email.');
      _startCooldown();
    } else {
      final errorMsg =
          ref.read(otpProvider).errorMessage ?? 'Could not resend OTP.';
      ToastService.error(context, errorMsg);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);
    final isLoading = otpState.isLoading;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Verify Email',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter the 6-digit code sent to your email\nto activate your account.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Verify your email',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the 6-digit code sent to your email',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // OTP input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_otpLength, (index) {
                        return _OtpBox(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          onChanged: (v) => _onDigitChanged(index, v),
                          onBackspace: () => _onBackspace(index),
                        );
                      }),
                    ),

                    const SizedBox(height: 40),

                    // Verify button
                    PrimaryButton(
                      label: 'Verify',
                      onPressed: _otpComplete ? _handleVerify : null,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Resend row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive a code? ",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: _canResend ? _handleResend : null,
                          child: Text(
                            _canResend
                                ? 'Resend code'
                                : 'Resend in ${_remainingSeconds}s',
                            style: TextStyle(
                              color: _canResend
                                  ? AppColors.secondary
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Back to register link
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text(
                        '← Back to Register',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single OTP digit box widget
// ---------------------------------------------------------------------------

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2, // Allow 2 so paste detection works in onChanged
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
