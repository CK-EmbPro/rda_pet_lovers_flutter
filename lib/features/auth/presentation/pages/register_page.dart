import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/utils/toast_service.dart';
import '../../../../data/providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  int _currentStep = 0; // 0 = info, 1 = persona selection
  String? _selectedPersona;

  final List<Map<String, dynamic>> _personas = [
    {'id': 'USER', 'label': 'User', 'icon': Icons.person},
    {'id': 'PET_OWNER', 'label': 'Pet Owner', 'icon': Icons.pets},
    {'id': 'SHOP_OWNER', 'label': 'Shop Owner', 'icon': Icons.store},
    {'id': 'VETERINARY', 'label': 'Veterinary', 'icon': Icons.medical_services},
    {'id': 'PET_GROOMER', 'label': 'Pet Groomer', 'icon': Icons.content_cut},
    // {'id': 'PET_TRAINER', 'label': 'Pet Trainer', 'icon': Icons.sports},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else {
      _handleRegister();
    }
  }

  Future<void> _handleRegister() async {
    if (_selectedPersona == null) {
      ToastService.error(context, 'Please select a persona');
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    await ref.read(authStateProvider.notifier).register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      role: _selectedPersona!,
    );

    final authState = ref.read(authStateProvider);

    if (authState.hasError) {
      if (mounted) {
        ToastService.error(context, authState.error.toString());
      }
    } else if (authState.value != null) {
      if (mounted) {
        ToastService.success(context, 'Account created successfully! Please login.');
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sign Up !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Provide required credentials below\nto create your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Form
              Padding(
                padding: const EdgeInsets.all(24),
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Center(
                                  child: Text('SIGN UP', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.go('/login'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: const Center(
                                  child: Text('Login', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress Indicator
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: _currentStep >= 1 ? AppColors.secondary : AppColors.inputFill,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Step Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentStep == 0 ? _buildInfoStep() : _buildPersonaStep(),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    if (_currentStep > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextButton(
                          onPressed: () => setState(() => _currentStep = 0),
                          child: const Text('← Back'),
                        ),
                      ),
                    PrimaryButton(
                      label: _currentStep == 0 ? 'Next' : 'Submit',
                      onPressed: _handleNext,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text('Login', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ),
                      ],
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

  Widget _buildInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'Full Names *',
            hint: 'e.g: John Doe',
            prefixIcon: Icons.person_outline,
            controller: _nameController,
            validator: (v) => v!.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          // Removed National ID field as it is not present in DTO
          AppTextField(
            label: 'Email',
            hint: 'pet@gmail.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty ? 'Email is required' : null, // Added validator
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone *',
            hint: '+250788123456', // Updated hint to match backend requirement
            prefixIcon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? 'Phone is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose your persona', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Wrap( // Changed Row to Wrap to handle more items
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _personas.map((p) {
            final isSelected = _selectedPersona == p['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedPersona = p['id']),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary.withValues(alpha: 0.2) : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? Border.all(color: AppColors.secondary, width: 2) : null,
                    ),
                    child: Icon(p['icon'] as IconData, size: 32, color: isSelected ? AppColors.secondary : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Password',
          hint: '********',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          controller: _passwordController,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Must be at least 8 characters (Upper, Lower, Number, Special)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
