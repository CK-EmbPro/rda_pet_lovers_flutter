import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/species_provider.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/models.dart';

class PetFormSheet extends ConsumerStatefulWidget {
  final PetModel? pet;

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
  final _healthController = TextEditingController();
  final _descController = TextEditingController();
  // Ancestry Controllers
  final _motherController = TextEditingController();
  final _fatherController = TextEditingController();
  final _grandMotherController = TextEditingController(); 
  final _grandFatherController = TextEditingController();

  // Vaccination State
  final List<Map<String, dynamic>> _addedVaccinations = [];
  String? _selectedVaccinationId;
  DateTime _vaccinationDate = DateTime.now();

  // Restored State Variables
  String? _selectedSpeciesId;
  String? _selectedBreedId;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  XFile? _profileImage;
  List<XFile> _galleryImages = [];
  bool _isLoading = false;
  bool _isForSale = false;

  final _picker = ImagePicker();
  final _storageService = StorageService(DioClient());

  @override
  void initState() {
    super.initState();
    if (widget.pet != null) {
      _nameController.text = widget.pet!.name;
      _selectedSpeciesId = widget.pet!.species?.id;
      _selectedBreedId = widget.pet!.breed?.id;
      _selectedGender = widget.pet!.gender;
      _ageController.text = widget.pet!.ageYears?.toString() ?? '';
      _weightController.text = widget.pet!.weightKg?.toString() ?? '';
      _descController.text = widget.pet!.description ?? '';
      _healthController.text = widget.pet!.healthSummary ?? '';
      _nationalityController.text = widget.pet!.nationality ?? '';
      _isForSale = widget.pet!.isForSale;
      _priceController.text = widget.pet!.price?.toString() ?? '';
      
      // Parse BirthDate
      if (widget.pet!.birthDate != null) {
        _selectedBirthDate = widget.pet!.birthDate;
      }

      // Pre-fill ancestry from metadata if available
      if (widget.pet!.metadata != null) {
        _motherController.text = widget.pet!.metadata!['motherPetCode'] ?? '';
        _fatherController.text = widget.pet!.metadata!['fatherPetCode'] ?? '';
        _grandMotherController.text = widget.pet!.metadata!['grandmotherPetCode'] ?? '';
        _grandFatherController.text = widget.pet!.metadata!['grandfatherPetCode'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _healthController.dispose();
    _descController.dispose();
    _nationalityController.dispose();
    _priceController.dispose();
    _motherController.dispose();
    _fatherController.dispose();
    _grandMotherController.dispose();
    _grandFatherController.dispose();
    super.dispose();
  }

  // ... (Image Picker methods unchanged)

  // ─── Image Picker Methods ─────────────────────

  void _showImageSourcePicker({required bool isProfile}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isProfile ? 'Profile Photo' : 'Add Gallery Photos',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickFromCamera(isProfile: isProfile);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isProfile) {
                        _pickProfileFromGallery();
                      } else {
                        _pickGalleryFromGallery();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera({required bool isProfile}) async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) {
      setState(() {
        if (isProfile) {
          _profileImage = image;
        } else {
          if (_galleryImages.length < 4) {
            _galleryImages.add(image);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 4 gallery images allowed')),
            );
          }
        }
      });
    }
  }

  Future<void> _pickProfileFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _profileImage = image);
    }
  }

  Future<void> _pickGalleryFromGallery() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        final remaining = 4 - _galleryImages.length;
        _galleryImages.addAll(images.take(remaining));
        if (images.length > remaining) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Only $remaining more image${remaining == 1 ? '' : 's'} allowed (max 4)')),
          );
        }
      });
    }
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryImages.removeAt(index));
  }

  // ─── Birth Date Picker ────────────────────────

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  // ─── Submit ───────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpeciesId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a species')),
      );
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload profile image if any
      String? profileUrl;
      if (_profileImage != null) {
        profileUrl = await _storageService.uploadFile(_profileImage!.path, folder: 'pets');
      }

      // 2. Upload gallery images if any
      List<String> galleryUrls = [];
      if (_galleryImages.isNotEmpty) {
        final paths = _galleryImages.map((f) => f.path).toList();
        galleryUrls = await _storageService.uploadMultiple(paths, folder: 'pets');
      }

      // Combine: profile first, then gallery
      final allImages = <String>[
        if (profileUrl != null) profileUrl,
        ...galleryUrls,
      ];

      // Prepare Metadata (Ancestry)
      final metadata = <String, dynamic>{
        if (_motherController.text.isNotEmpty) 'motherPetCode': _motherController.text.trim(),
        if (_fatherController.text.isNotEmpty) 'fatherPetCode': _fatherController.text.trim(),
        if (_grandMotherController.text.isNotEmpty) 'grandmotherPetCode': _grandMotherController.text.trim(),
        if (_grandFatherController.text.isNotEmpty) 'grandfatherPetCode': _grandFatherController.text.trim(),
      };

      // 3. Create Pet
      final pet = await ref.read(petCrudProvider.notifier).createPet(
        name: _nameController.text.trim(),
        speciesId: _selectedSpeciesId!,
        gender: _selectedGender!,
        breedId: _selectedBreedId,
        ageYears: int.tryParse(_ageController.text),
        weightKg: double.tryParse(_weightController.text),
        birthDate: _selectedBirthDate?.toIso8601String(),
        nationality: _nationalityController.text.isNotEmpty
            ? _nationalityController.text.trim()
            : null,
        images: allImages.isNotEmpty ? allImages : null,
        healthSummary: _healthController.text.isNotEmpty
            ? _healthController.text.trim()
            : null,
        description: _descController.text.isNotEmpty
            ? _descController.text.trim()
            : null,
        metadata: metadata.isNotEmpty ? metadata : null,
        vaccinations: _addedVaccinations.isNotEmpty ? _addedVaccinations : null,
      );

      // 4. List for Sale if selected
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
          const SnackBar(
            content: Text('Pet saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register pet: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final speciesAsync = ref.watch(speciesProvider);
    final breedsAsync = _selectedSpeciesId != null
        ? ref.watch(breedsProvider(_selectedSpeciesId!))
        : const AsyncValue.data(<BreedModel>[]);
    
    // Fetch vaccinations for selected species (or all if none selected, though simplified to species)
    // We reuse the catalog provider, but strictly we might want to filter by species ID if the catalog is huge
    // For now we assume catalog is small enough or we filter client side.
    final vaccinationCatalogAsync = ref.watch(vaccinationCatalogProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag handle
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
                    // ── Profile Image ──
                    _buildProfileImageSection(),
                    const SizedBox(height: 20),

                    // ── Gallery Images ──
                    _buildGallerySection(),
                    const SizedBox(height: 24),

                    // ── Name ──
                    AppTextField(
                      label: 'Pet Name',
                      hint: 'e.g. Buddy',
                      controller: _nameController,
                      validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Species & Breed ──
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
                                // clear vaccinations if species changes? maybe better to keep until logic is firm
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

                    // ── Gender & Age ──
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
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Age (years)',
                            hint: 'e.g. 2',
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Weight & Nationality ──
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Weight (kg)',
                            hint: 'e.g. 15',
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Nationality',
                            hint: 'e.g. Rwandan',
                            controller: _nationalityController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Birth Date ──
                    _buildBirthDatePicker(),
                    const SizedBox(height: 16),

                    // ── Health Summary ──
                    AppTextField(
                      label: 'Health Summary',
                      hint: 'e.g. Vaccinated, dewormed...',
                      maxLines: 3,
                      controller: _healthController,
                    ),
                    const SizedBox(height: 24),

                    // ── Vaccinations Section ──
                    _buildVaccinationSection(vaccinationCatalogAsync),
                    const SizedBox(height: 24),

                    // ── Ancestry Section ──
                    _buildAncestrySection(),
                    const SizedBox(height: 24),

                    // ── Description ──
                    AppTextField(
                      label: 'Description',
                      hint: 'Tell us more about your pet...',
                      maxLines: 4,
                      controller: _descController,
                    ),
                    const SizedBox(height: 24),

                    // ── List for Sale Section ──
                    _buildSaleSection(),
                    const SizedBox(height: 24),

                    // ── Submit Button ──
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

  // ─── New Sections ───

  Widget _buildVaccinationSection(AsyncValue<List<dynamic>> catalogAsync) {
    // Note: catalogAsync returns List<VaccinationModel>
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vaccinations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Add recent vaccinations', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        
        // Added vaccinations list
        if (_addedVaccinations.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _addedVaccinations.map((vac) {
              final date = DateTime.tryParse(vac['administeredAt']);
              final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';
              // We need the name - bit tricky since we store ID. We can lookup or just store name too for display.
              // For simplicity, let's store name in logic when adding.
              return Chip(
                label: Text('${vac['name']} ($dateStr)'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _addedVaccinations.remove(vac));
                },
                backgroundColor: AppColors.inputFill,
                labelStyle: const TextStyle(fontSize: 12),
              );
            }).toList(),
          ),
        
        if (_addedVaccinations.isNotEmpty) const SizedBox(height: 12),

        // Add Vaccination Controls
        catalogAsync.when(
          data: (vaccinations) {
            // Filter by selected species if known? The catalog returned might encompass all, 
            // but we can filter simply if models have speciesId. 
            // Current model definitions might not have species relation on client fully filtered, 
            // but let's assume all valid for now or filter if we can. 
            // NOTE: VaccinationModel doesn't strictly have speciesId visible in the simple snippet we saw earlier?
            // Wait, we do not have speciesId in VaccinationModel in `vaccination_service.dart` snippet!
            // We'll list all for now.
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Vaccination'),
                      value: _selectedVaccinationId,
                      items: vaccinations.map((v) => DropdownMenuItem(
                        value: v.id,
                        child: Text(v.name),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedVaccinationId = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Date picker for vax
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _vaccinationDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.secondary)),
                                child: child!,
                              ),
                            );
                            if (picked != null) setState(() => _vaccinationDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Text('${_vaccinationDate.day}/${_vaccinationDate.month}/${_vaccinationDate.year}', style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Button
                      GestureDetector(
                        onTap: () {
                          if (_selectedVaccinationId == null) return;
                          final vaxDef = vaccinations.firstWhere((v) => v.id == _selectedVaccinationId);
                          setState(() {
                            _addedVaccinations.add({
                              'vaccinationId': _selectedVaccinationId,
                              'administeredAt': _vaccinationDate.toIso8601String(),
                              'name': vaxDef.name, // Helpher for display
                            });
                            _selectedVaccinationId = null; // Reset selection
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_,__) => const Text('Could not load vaccinations'),
        ),
      ],
    );
  }

  Widget _buildAncestrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ancestry (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Enter pet codes if known (e.g. PET-2024-...)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Mother Code',
                hint: 'Mother',
                controller: _motherController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Father Code',
                hint: 'Father',
                controller: _fatherController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Grandmother Code',
                hint: 'Grandmother',
                controller: _grandMotherController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Grandfather Code',
                hint: 'Grandfather',
                controller: _grandFatherController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Widgets ──────────────────────────────────

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pet Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Main photo of your pet', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () => _showImageSourcePicker(isProfile: true),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  width: 2,
                ),
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(File(_profileImage!.path)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 40, color: AppColors.secondary),
                        const SizedBox(height: 4),
                        Text('Add Profile', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => setState(() => _profileImage = null),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Pet Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Text('${_galleryImages.length}/4', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Additional photos (up to 4)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              // Gallery images
              ..._galleryImages.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(file.path),
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeGalleryImage(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Add button (only if < 4)
              if (_galleryImages.length < 4)
                GestureDetector(
                  onTap: () => _showImageSourcePicker(isProfile: false),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppColors.secondary),
                        const SizedBox(height: 4),
                        Text('Add Photo', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Birth Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickBirthDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  _selectedBirthDate != null
                      ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                      : 'Select birth date (optional)',
                  style: TextStyle(
                    color: _selectedBirthDate != null ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_selectedBirthDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedBirthDate = null),
                    child: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleSection() {
    return Container(
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
