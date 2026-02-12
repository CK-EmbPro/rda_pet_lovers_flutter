import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/species_provider.dart'; // Static data
import '../../../data/providers/pet_providers.dart';
import '../../../data/models/models.dart';

class PetFormSheet extends ConsumerStatefulWidget {
  final PetModel? pet; // If provided, strictly for editing (not implemented yet for this task)

  const PetFormSheet({super.key, this.pet});

  static void show(BuildContext context, {PetModel? pet}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PetFormSheet(pet: pet),
    );
  }

  @override
  ConsumerState<PetFormSheet> createState() => _PetFormSheetState();
}

class _PetFormSheetState extends ConsumerState<PetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _locationController = TextEditingController();
  final _healthController = TextEditingController();
  final _descController = TextEditingController();
  
  final _priceController = TextEditingController(); // Added
  
  String? _selectedSpeciesId;
  String? _selectedBreedId;
  String? _selectedGender;
  XFile? _imageFile;
  bool _isLoading = false;
  bool _isForSale = false; // Added

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      // Pre-fill for edit
      _nameController.text = widget.pet!.name;
      _selectedSpeciesId = widget.pet!.species?.id;
      _selectedBreedId = widget.pet!.breed?.id;
      _selectedGender = widget.pet!.gender;
      _ageController.text = widget.pet!.ageYears?.toString() ?? '';
      _weightController.text = widget.pet!.weightKg?.toString() ?? '';
      _descController.text = widget.pet!.description ?? '';
      _isForSale = widget.pet!.isForSale;
      _priceController.text = widget.pet!.price?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _locationController.dispose();
    _healthController.dispose();
    _descController.dispose();
    _priceController.dispose(); // Added
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpeciesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a species')));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a gender')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final breedId = _selectedBreedId;

      // 1. Create Pet
      final pet = await ref.read(petCrudProvider.notifier).createPet(
        name: _nameController.text,
        speciesId: _selectedSpeciesId!,
        gender: _selectedGender!,
        breedId: breedId,
        ageYears: int.tryParse(_ageController.text),
        weightKg: double.tryParse(_weightController.text),
        locationId: _locationController.text.isNotEmpty ? _locationController.text : null,
        healthSummary: _healthController.text.isNotEmpty ? _healthController.text : null,
        description: _descController.text.isNotEmpty ? _descController.text : null,
      );

      // 2. List for Sale if selected
      if (pet != null && _isForSale) {
        final price = double.tryParse(_priceController.text) ?? 0.0;
        await ref.read(petCrudProvider.notifier).listForSale(
          pet.id,
          price: price,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet saved successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register pet: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speciesAsync = ref.watch(speciesProvider);
    final breedsAsync = _selectedSpeciesId != null 
        ? ref.watch(breedsProvider(_selectedSpeciesId!))
        : const AsyncValue.data(<BreedModel>[]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Add Your Pet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.secondary, width: 2),
                            image: _imageFile != null 
                                ? DecorationImage(image: FileImage(File(_imageFile!.path)), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _imageFile == null 
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: AppColors.secondary),
                                    const SizedBox(height: 4),
                                    Text('Add Photo', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Pet Name', 
                      hint: 'e.g. Buddy',
                      controller: _nameController,
                      validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: speciesAsync.when(
                            data: (species) => _buildDropdown(
                              'Species', 'Select species', 
                              species.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                              _selectedSpeciesId,
                              (v) => setState(() {
                                _selectedSpeciesId = v;
                                _selectedBreedId = null;
                              }),
                            ),
                            loading: () => _buildDropdown('Species', 'Loading...', [], null, null),
                            error: (e, s) => _buildDropdown('Species', 'Error', [], null, null),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: breedsAsync.when(
                            data: (breeds) => _buildDropdown(
                              'Breed', 'Select breed', 
                              breeds.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                              _selectedBreedId,
                              (v) => setState(() => _selectedBreedId = v),
                            ),
                            loading: () => _buildDropdown('Breed', 'Loading...', [], null, null),
                            error: (e, s) => _buildDropdown('Breed', 'Error', [], null, null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Gender', 'Select gender', 
                            const [
                              DropdownMenuItem(value: 'MALE', child: Text('Male')),
                              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                            ],
                            _selectedGender,
                            (v) => setState(() => _selectedGender = v),
                          )
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Age', 
                            hint: 'e.g. 2', 
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Weight (kg)', 
                      hint: 'e.g. 15', 
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    // Location might be a dropdown in real app, simplified here
                    AppTextField(label: 'Location', hint: 'e.g. Kicukiro', controller: _locationController),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Health Summary',
                      hint: 'e.g. Vaccinated...',
                      maxLines: 3,
                      controller: _healthController,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Description',
                      hint: 'Tell us more...',
                      maxLines: 4,
                      controller: _descController,
                    ),
                    const SizedBox(height: 24),
                    
                    // List for Sale Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('List for Sale?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Post this pet to the marketplace', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              Switch(
                                value: _isForSale,
                                onChanged: (v) => setState(() => _isForSale = v),
                              ),
                            ],
                          ),
                          if (_isForSale) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Price (RWF)',
                              hint: 'e.g. 50000',
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              validator: (v) => _isForSale && (v?.isEmpty ?? true) ? 'Price is required' : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: _isLoading ? 'Processing...' : 'Save Pet',
                        onPressed: _isLoading ? null : _submit,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String hint, List<DropdownMenuItem<String>> items, String? value, ValueChanged<String?>? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
              items: items,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
