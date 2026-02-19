import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/models/models.dart';

class ServiceFormSheet extends ConsumerStatefulWidget {
  final ServiceModel? service; // If provided, we are in Edit mode

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
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descController = TextEditingController();
  
  String _paymentMethod = 'PAY_BEFORE'; // Default
  String _serviceType = 'GROOMING'; // Default
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _priceController.text = widget.service!.fee.toInt().toString();
      _durationController.text = widget.service!.durationMinutes?.toString() ?? '60';
      _descController.text = widget.service!.description ?? '';
      _paymentMethod = widget.service!.paymentMethod;
      _serviceType = widget.service!.serviceType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text;
      final fee = double.tryParse(_priceController.text) ?? 0;
      final duration = int.tryParse(_durationController.text) ?? 60;
      final description = _descController.text;

      if (widget.service == null) {
        // Create
        await ref.read(serviceCrudProvider.notifier).createService(
          name: name,
          basePrice: fee,
          description: description,
          durationMinutes: duration,
          paymentType: _paymentMethod,
        );
      } else {
        // Update
        // await ref.read(serviceCrudProvider.notifier).updateService(...)
        AppToast.info(context, 'Service update coming soon');
      }

      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, widget.service == null ? 'Service created!' : 'Service updated!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save service. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.service == null ? 'Create New Service' : 'Edit Service',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Service Name', 
                      hint: 'e.g: Pet Grooming', 
                      prefixIcon: Icons.design_services,
                      controller: _nameController,
                      validator: (v) => v?.isNotEmpty == true ? null : 'Name required',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Price (RWF)', 
                            hint: '25000', 
                            prefixIcon: Icons.monetization_on,
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                          )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Duration (min)', 
                            hint: '60', 
                            prefixIcon: Icons.timer,
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Service Type Dropdown
                    const Text('Service Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _serviceType,
                          items: const [
                            DropdownMenuItem(value: 'GROOMING', child: Text('Grooming')),
                            DropdownMenuItem(value: 'WALKING', child: Text('Walking')),
                            DropdownMenuItem(value: 'TRAINING', child: Text('Training')),
                            DropdownMenuItem(value: 'VETERINARY', child: Text('Veterinary')),
                            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                          ],
                          onChanged: (v) => setState(() => _serviceType = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment Method
                    const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Pay Before', style: TextStyle(fontSize: 12)),
                            value: 'PAY_BEFORE',
                            // ignore: deprecated_member_use
                            groupValue: _paymentMethod,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Pay After', style: TextStyle(fontSize: 12)),
                            value: 'PAY_AFTER',
                            // ignore: deprecated_member_use
                            groupValue: _paymentMethod,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Description', 
                      hint: 'Describe your service...', 
                      prefixIcon: Icons.description,
                      controller: _descController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: _isLoading ? 'Saving...' : (widget.service == null ? 'Create Service' : 'Save Changes'), 
                        onPressed: _isLoading ? null : _submit,
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
  }
}
