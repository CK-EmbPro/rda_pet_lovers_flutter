import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentStep = 0; // 0 = info, 1 = persona selection
  String? _selectedPersona;

  final List<Map<String, dynamic>> _personas = [
    {'id': 'user', 'label': 'User', 'icon': Icons.person},
    {'id': 'pet_owner', 'label': 'Pet Owner', 'icon': Icons.pets},
    {'id': 'shop_owner', 'label': 'Shop Owner', 'icon': Icons.store},
    {'id': 'provider', 'label': 'Service Provider', 'icon': Icons.medical_services},
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

  void _handleRegister() {
    if (_selectedPersona == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a persona')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Mock registration
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Provide required credentials below\nto create your account',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
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
                      isLoading: _isLoading,
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
          AppTextField(
            label: 'ID *',
            hint: '********',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email',
            hint: 'pet@gmail.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone *',
            hint: '+ (250) *** *** ***',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      color: isSelected ? AppColors.secondary.withOpacity(0.2) : AppColors.inputFill,
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
        const Text('Must be at least 8 characters', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
