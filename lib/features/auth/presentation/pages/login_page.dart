import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast_service.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/auth_providers.dart';
import '../../../../data/services/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

/// 2-step forgot-password bottom sheet.
/// Step 0: enter email → POST /auth/forgot-password
/// Step 1: enter reset token + new password → POST /auth/reset-password
class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  int _step = 0; // 0 = email, 1 = token+password
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final authService = AuthService(DioClient());
      await authService.forgotPassword(_emailController.text.trim());
      if (mounted) {
        setState(() { _step = 1; _loading = false; });
        ToastService.success(context, 'Reset token sent to your email');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ToastService.error(context, e.toString());
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final authService = AuthService(DioClient());
      await authService.resetPassword(
        _tokenController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ToastService.success(context, 'Password reset successfully! Please login.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ToastService.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: _step == 0 ? _buildEmailStep() : _buildResetStep(),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Forgot Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Enter your email and we\'ll send you a reset token.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Email',
            hint: 'pet@gmail.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? 'Email is required' : null,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send Reset Token',
            onPressed: _sendResetEmail,
            isLoading: _loading,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reset Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Enter the token from your email and your new password.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Reset Token',
            hint: 'Paste token from email',
            prefixIcon: Icons.vpn_key_outlined,
            controller: _tokenController,
            validator: (v) => (v == null || v.isEmpty) ? 'Token is required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'New Password',
            hint: '********',
            prefixIcon: Icons.lock_outline,
            controller: _passwordController,
            obscureText: _obscure,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Must be at least 8 characters';
              final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])');
              if (!regex.hasMatch(v)) return 'Must include upper, lower, number, and special character';
              return null;
            },
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Reset Password',
            onPressed: _resetPassword,
            isLoading: _loading,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('← Back'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ForgotPasswordSheet(),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Call real login API
      await ref.read(authStateProvider.notifier).login(email, password);

      // Check result via state (AuthNotifier sets state.error on failure)
      final authState = ref.read(authStateProvider);

      if (authState.hasError) {
        if (!mounted) return;

        final error = authState.error;

        if (error is UnverifiedAccountException) {
          // Account exists and credentials are correct but OTP not confirmed.
          // Show an informational toast and push the user to the verification screen.
          ToastService.info(
            context,
            'Your account is not verified. Redirecting to verification...',
          );
          context.push('/verify-otp?userId=${error.userId}');
        } else {
          // Generic login failure — show whatever message the service returned.
          ToastService.error(context, error.toString());
        }
      } else if (authState.value != null) {
        // Success
        if (mounted) {
          final user = authState.value!;
          _navigateToPortal(user);
        }
      }
    }
  }

  void _navigateToPortal(UserModel user) {
    final route = AppRouter.getPortalRoute(user.primaryRole);
    // Simple mapping for toast message
    String portalName = 'User';
    if (route.contains('pet-owner')) {
      portalName = 'Pet Owner';
    } else if (route.contains('shop-owner')) {
      portalName = 'Shop Owner';
    } else if (route.contains('provider')) {
      portalName = 'Service Provider';
    } else if (route.contains('admin')) {
      portalName = 'Admin';
    }

    ToastService.success(context, 'Welcome back, ${user.fullName}! ($portalName)');
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for loading status
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              // Header with dark blue design
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
                            // border: Border.all(color: Colors.white, width: 2), // Removed border
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.pets, size: 36, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Login !',
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
                      'Welcome back to Rwanda Pet Lovers,\nplease sign in to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Tab Switcher
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context.go('/register'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Email Field
                      AppTextField(
                        label: 'Email',
                        hint: 'pet@gmail.com',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password Field
                      AppTextField(
                        label: 'Password',
                        hint: '********',
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordSheet(context),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: AppColors.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Login Button
                      PrimaryButton(
                        label: 'Log In',
                        onPressed: _handleLogin,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
