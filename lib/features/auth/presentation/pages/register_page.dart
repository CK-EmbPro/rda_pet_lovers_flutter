import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _personaFormKey = GlobalKey<FormState>();
  final _petFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petBreedController = TextEditingController();

  bool _obscurePassword = true;
  int _currentStep = 0;
  String? _selectedPersona;
  String? _selectedSpecies;
  String? _selectedGender;
  int? _petAge;

  static const List<String> _speciesOptions = [
    'Dog', 'Cat', 'Rabbit', 'Bird', 'Fish', 'Guinea Pig', 'Hamster', 'Other',
  ];

  // SHOP_OWNER removed — admin-only registration
  final List<Map<String, dynamic>> _personas = [
    {'id': 'USER',        'label': 'User',        'icon': Icons.person},
    {'id': 'PET_OWNER',   'label': 'Pet Owner',   'icon': Icons.pets},
    {'id': 'VETERINARY',  'label': 'Veterinary',  'icon': Icons.medical_services},
    {'id': 'PET_GROOMER', 'label': 'Pet Groomer', 'icon': Icons.content_cut},
    {'id': 'PET_WALKER',  'label': 'Pet Walker',  'icon': Icons.directions_walk},
    {'id': 'PET_TRAINER', 'label': 'Pet Trainer', 'icon': Icons.fitness_center},
  ];

  bool get _isPetOwner => _selectedPersona == 'PET_OWNER';
  int get _totalSteps => _isPetOwner ? 3 : 2;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _petNameController.dispose();
    _petBreedController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_selectedPersona == null) {
        ToastService.error(context, 'Please select a persona');
        return;
      }
      if (_personaFormKey.currentState!.validate()) {
        if (_isPetOwner) {
          setState(() => _currentStep = 2);
        } else {
          _handleRegister();
        }
      }
    } else if (_currentStep == 2) {
      if (_petFormKey.currentState!.validate()) {
        _handleRegister();
      }
    }
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    final userId = await ref.read(authStateProvider.notifier).register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      role: _selectedPersona!,
      pet: _isPetOwner
          ? {
              'name': _petNameController.text.trim(),
              'speciesName': _selectedSpecies,
              'breedName': _petBreedController.text.trim().isEmpty
                  ? null
                  : _petBreedController.text.trim(),
              'gender': _selectedGender,
              if (_petAge != null) 'ageYears': _petAge,
            }
          : null,
    );

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.hasError || userId == null) {
      ToastService.error(
        context,
        authState.hasError ? authState.error.toString() : 'Registration failed.',
      );
    } else {
      ToastService.info(
          context, 'A 6-digit verification code was sent to your email.');
      context.go('/verify-otp?userId=$userId');
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
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildTabSwitcher(),
                    const SizedBox(height: 16),
                    _buildProgressBar(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey(_currentStep),
                        child: _currentStep == 0
                            ? _buildInfoStep()
                            : _currentStep == 1
                                ? _buildPersonaStep()
                                : _buildPetStep(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_currentStep > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextButton(
                          onPressed: () => setState(() => _currentStep--),
                          child: const Text('← Back'),
                        ),
                      ),
                    PrimaryButton(
                      label: _currentStep == 0
                          ? 'Next'
                          : (_currentStep == 1 && _isPetOwner
                              ? 'Next'
                              : 'Create Account'),
                      onPressed: _handleNext,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text('Login',
                              style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold)),
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

  Widget _buildHeader() {
    return Container(
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
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child:
                    const Icon(Icons.pets, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Text(
                'Sign Up !',
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
            'Provide required credentials below\nto create your account',
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text('SIGN UP',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
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
                  child: Text('Login',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final filled = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin:
                EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: filled ? AppColors.secondary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
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
            label: 'Email',
            hint: 'pet@gmail.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone *',
            hint: '+250788123456',
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
    return Form(
      key: _personaFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('Choose your persona',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _personas.map((p) {
              final isSelected = _selectedPersona == p['id'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedPersona = p['id']),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.secondary, width: 2)
                            : null,
                      ),
                      child: Icon(p['icon'] as IconData,
                          size: 32,
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            controller: _passwordController,
            suffix: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Must be at least 8 characters';
              final regex = RegExp(
                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])');
              if (!regex.hasMatch(v))
                return 'Must include upper, lower, number, and special character';
              return null;
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Must be at least 8 characters (Upper, Lower, Number, Special)',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPetStep() {
    return Form(
      key: _petFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pets,
                      color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tell us about your pet',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 2),
                      Text(
                          'Add your first pet to complete registration',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          AppTextField(
            label: 'Pet Name *',
            hint: 'e.g: Buddy',
            prefixIcon: Icons.badge_outlined,
            controller: _petNameController,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Pet name is required'
                : null,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedSpecies,
            decoration: _dropdownDecoration('Species *', Icons.category_outlined),
            hint: const Text('Select species',
                style: TextStyle(color: AppColors.textMuted)),
            items: _speciesOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedSpecies = v),
            validator: (v) => v == null ? 'Species is required' : null,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Breed (optional)',
            hint: 'e.g: Golden Retriever',
            prefixIcon: Icons.pets_outlined,
            controller: _petBreedController,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: _dropdownDecoration('Gender *', Icons.transgender),
            hint: const Text('Select gender',
                style: TextStyle(color: AppColors.textMuted)),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Male')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            ],
            onChanged: (v) => setState(() => _selectedGender = v),
            validator: (v) => v == null ? 'Gender is required' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            decoration: _dropdownDecoration(
                'Age in years (optional)', Icons.cake_outlined)
              .copyWith(hintText: 'e.g: 2',
                  hintStyle: const TextStyle(color: AppColors.textMuted)),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => _petAge = int.tryParse(v),
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                final age = int.tryParse(v);
                if (age == null || age < 0 || age > 50) {
                  return 'Enter a valid age (0–50)';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppColors.error)),
    );
  }
}
