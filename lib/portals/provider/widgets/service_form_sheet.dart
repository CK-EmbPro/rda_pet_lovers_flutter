import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/models/models.dart';

/// Bottom sheet for creating or editing a service.
/// All fields are sourced from the backend `CreateServiceDto`.
class ServiceFormSheet extends ConsumerStatefulWidget {
  final ServiceModel? service;

  const ServiceFormSheet({super.key, this.service});

  static void show(BuildContext context, {ServiceModel? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ServiceFormSheet(service: service),
    );
  }

  @override
  ConsumerState<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _priceYoungController = TextEditingController();
  final _priceOldController = TextEditingController();
  final _durationController = TextEditingController();
  final _descController = TextEditingController();

  // State
  String _paymentType = 'PAY_UPFRONT';
  String? _categoryId;

  // Derived: requiresSubscription is true iff paymentType == SUBSCRIPTION
  bool get _requiresSubscription => _paymentType == 'SUBSCRIPTION';
  bool _isLoading = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  /// Pre-populate all fields when editing an existing service
  void _populateFields() {
    final s = widget.service;
    if (s == null) return;
    _nameController.text = s.name;
    _basePriceController.text = s.basePrice.toStringAsFixed(0);
    _priceYoungController.text = s.priceYoungPet?.toStringAsFixed(0) ?? '';
    _priceOldController.text = s.priceOldPet?.toStringAsFixed(0) ?? '';
    _durationController.text = s.durationMinutes?.toString() ?? '';
    _descController.text = s.description ?? '';
    _paymentType = s.paymentType;
    _categoryId = s.categoryId;
    // requiresSubscription is derived from paymentType, no need to pre-populate separately
  }

  @override
  void dispose() {
    _nameController.dispose();
    _basePriceController.dispose();
    _priceYoungController.dispose();
    _priceOldController.dispose();
    _durationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final basePrice = double.tryParse(_basePriceController.text) ?? 0;
      final priceYoungPet = double.tryParse(_priceYoungController.text);
      final priceOldPet = double.tryParse(_priceOldController.text);
      final durationMinutes = int.tryParse(_durationController.text);
      final description = _descController.text.trim();

      ActionResponse<ServiceModel> result;

      if (!_isEditing) {
        // CREATE
        result = await ref.read(serviceCrudProvider.notifier).createService(
              name: name,
              basePrice: basePrice,
              description: description.isNotEmpty ? description : null,
              paymentType: _paymentType,
              priceYoungPet: priceYoungPet,
              priceOldPet: priceOldPet,
              durationMinutes: durationMinutes,
              categoryId: _categoryId,
              requiresSubscription: _requiresSubscription,
            );
      } else {
        // UPDATE — send only the UpdateServiceDto-compatible keys
        final updates = <String, dynamic>{
          'name': name,
          'basePrice': basePrice,
          'paymentType': _paymentType,
          'requiresSubscription': _requiresSubscription,
          if (description.isNotEmpty) 'description': description,
          if (priceYoungPet != null) 'priceYoungPet': priceYoungPet,
          if (priceOldPet != null) 'priceOldPet': priceOldPet,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (_categoryId != null) 'categoryId': _categoryId,
        };
        result = await ref
            .read(serviceCrudProvider.notifier)
            .updateService(widget.service!.id, updates);
      }

      debugPrint('[ServiceForm] result: success=${result.success}, msg="${result.message}"');

      if (mounted) {
        if (result.success) {
          Navigator.pop(context);
          AppToast.success(context, result.message);
          ref.invalidate(myServicesProvider);
        } else {
          AppToast.error(context, result.message);
        }
      }
    } catch (e) {
      debugPrint('[ServiceForm] unexpected error: $e');
      if (mounted) {
        AppToast.error(context, 'Unexpected error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(serviceApiCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Service' : 'Create New Service',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(backgroundColor: AppColors.inputFill),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Divider(),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                      20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Service Name ───────────────────────────────
                        AppTextField(
                          label: 'Service Name *',
                          hint: 'e.g. Premium Dog Grooming',
                          prefixIcon: Icons.design_services_outlined,
                          controller: _nameController,
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Service name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // ─── Base Price ──────────────────────────────────
                        AppTextField(
                          label: 'Base Price (RWF) *',
                          hint: '25000',
                          prefixIcon: Icons.payments_outlined,
                          controller: _basePriceController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v?.trim().isEmpty ?? true) return 'Price is required';
                            if (double.tryParse(v!) == null) return 'Enter a valid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ─── Pricing Tiers (optional) ────────────────────
                        const _SectionLabel(
                          label: 'Price Tiers (Optional)',
                          subtitle: 'Set different prices by pet age',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Young Pet (RWF)',
                                hint: '20000',
                                prefixIcon: Icons.child_care_outlined,
                                controller: _priceYoungController,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Old Pet (RWF)',
                                hint: '30000',
                                prefixIcon: Icons.elderly_outlined,
                                controller: _priceOldController,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ─── Duration ────────────────────────────────────
                        AppTextField(
                          label: 'Duration (minutes)',
                          hint: '60',
                          prefixIcon: Icons.timer_outlined,
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                              return 'Enter whole minutes';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ─── Category ────────────────────────────────────
                        const _SectionLabel(label: 'Category'),
                        const SizedBox(height: 8),
                        categoriesAsync.when(
                          loading: () => Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (_, __) => Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Could not load categories',
                              style: TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                          data: (categories) => _CategoryDropdown(
                            categories: categories,
                            value: _categoryId,
                            onChanged: (id) => setState(() => _categoryId = id),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ─── Payment Type ────────────────────────────────
                        const _SectionLabel(label: 'Payment Type'),
                        const SizedBox(height: 8),
                        _PaymentTypeSelector(
                          value: _paymentType,
                          onChanged: (v) => setState(() => _paymentType = v),
                        ),
                        const SizedBox(height: 16),

                        // ─── Description ─────────────────────────────────
                        AppTextField(
                          label: 'Description',
                          hint: 'Describe your service in detail...',
                          prefixIcon: Icons.description_outlined,
                          controller: _descController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 28),

                        // ─── Submit Button ───────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isEditing ? 'Save Changes' : 'Create Service',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? subtitle;

  const _SectionLabel({required this.label, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<ServiceCategory> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Validate that the current value is actually in the list
    final validValue = categories.any((c) => c.id == value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: validValue,
          hint: const Text('Select a category (optional)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          onChanged: onChanged,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No category', style: TextStyle(color: AppColors.textMuted)),
            ),
            ...categories.map(
              (cat) => DropdownMenuItem<String>(
                value: cat.id,
                child: Text(cat.name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PaymentTypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('PAY_UPFRONT', 'Pay Upfront', Icons.payment),
      ('PAY_AFTER', 'Pay After', Icons.schedule),
      ('SUBSCRIPTION', 'Subscription', Icons.autorenew),
    ];

    return Row(
      children: options.map((opt) {
        final (val, label, icon) = opt;
        final isSelected = value == val;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

