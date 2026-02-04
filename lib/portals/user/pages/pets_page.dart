import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';

class PetsPage extends ConsumerStatefulWidget {
  const PetsPage({super.key});

  @override
  ConsumerState<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends ConsumerState<PetsPage> {
  bool _isGridView = true;
  String? _selectedSpecies;

  @override
  Widget build(BuildContext context) {
    final species = ref.watch(speciesProvider);
    final allPets = ref.watch(browsablePetsProvider);
    
    // Filter pets by species if selected
    final pets = _selectedSpecies == null
        ? allPets
        : allPets.where((p) => p.speciesId == _selectedSpecies).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Browse Pets',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _ViewToggle(
                          icon: Icons.grid_view,
                          isActive: _isGridView,
                          onTap: () => setState(() => _isGridView = true),
                        ),
                        const SizedBox(width: 8),
                        _ViewToggle(
                          icon: Icons.view_carousel,
                          isActive: !_isGridView,
                          onTap: () => setState(() => _isGridView = false),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Species Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: species.length + 1, // +1 for "All" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedSpecies == null;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSpecies = null),
                            child: _FilterChip(label: 'All', isSelected: isSelected),
                          ),
                        );
                      }
                      final sp = species[index - 1];
                      final isSelected = _selectedSpecies == sp.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSpecies = sp.id),
                          child: _FilterChip(
                            label: '${sp.icon ?? ''} ${sp.name}'.trim(),
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: pets.isEmpty
                ? const EmptyState(
                    icon: Icons.pets,
                    title: 'No Pets Found',
                    subtitle: 'No pets available in this category',
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isGridView ? _buildGridView(pets) : _buildCarouselView(pets),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<PetModel> pets) {
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: pets.length,
      itemBuilder: (context, index) => _PetGridCard(pet: pets[index]),
    );
  }

  Widget _buildCarouselView(List<PetModel> pets) {
    return PageView.builder(
      key: const ValueKey('carousel'),
      controller: PageController(viewportFraction: 0.85),
      itemCount: pets.length,
      itemBuilder: (context, index) => _PetCarouselCard(pet: pets[index]),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggle({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: isActive ? AppColors.secondary : Colors.white),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.secondary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final PetModel pet;
  const _PetGridCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPetDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: pet.displayImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: pet.displayImage,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.inputFill),
                        errorWidget: (_, __, ___) => _petPlaceholder(),
                      )
                    : _petPlaceholder(),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Icon(
                          pet.gender == 'MALE' ? Icons.male : Icons.female,
                          size: 16,
                          color: pet.gender == 'MALE' ? AppColors.secondary : Colors.pink,
                        ),
                      ],
                    ),
                    Text(
                      pet.breed?.name ?? pet.species?.name ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          pet.ageYears != null
                              ? (pet.ageYears! < 1 ? '< 1 yr' : '${pet.ageYears} yr')
                              : '?',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
    );
  }

  Widget _petPlaceholder() {
    return Container(
      color: AppColors.inputFill,
      child: const Center(child: Icon(Icons.pets, size: 40, color: AppColors.secondary)),
    );
  }

  void _showPetDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PetDetailsSheet(pet: pet),
    );
  }
}

class _PetCarouselCard extends StatelessWidget {
  final PetModel pet;
  const _PetCarouselCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: pet.displayImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: pet.displayImage,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.inputFill),
                      errorWidget: (_, __, ___) => _petPlaceholder(),
                    )
                  : _petPlaceholder(),
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pet.name, style: AppTypography.h2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pet.gender == 'MALE'
                              ? AppColors.secondary.withOpacity(0.1)
                              : Colors.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pet.gender == 'MALE' ? Icons.male : Icons.female,
                              size: 16,
                              color: pet.gender == 'MALE' ? AppColors.secondary : Colors.pink,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pet.gender == 'MALE' ? 'Male' : 'Female',
                              style: TextStyle(
                                fontSize: 12,
                                color: pet.gender == 'MALE' ? AppColors.secondary : Colors.pink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.breed?.name ?? pet.species?.name ?? '',
                    style: AppTypography.bodySmall,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      FeatureChip(
                        icon: Icons.calendar_today,
                        label: pet.ageYears != null
                            ? (pet.ageYears! < 1 ? '< 1 year' : '${pet.ageYears} year${pet.ageYears! > 1 ? 's' : ''}')
                            : 'Unknown',
                      ),
                      const SizedBox(width: 8),
                      if (pet.weightKg != null)
                        FeatureChip(icon: Icons.monitor_weight, label: '${pet.weightKg} kg'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'View Details',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _PetDetailsSheet(pet: pet),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _petPlaceholder() {
    return Container(
      color: AppColors.inputFill,
      child: const Center(child: Icon(Icons.pets, size: 80, color: AppColors.secondary)),
    );
  }
}

class _PetDetailsSheet extends StatelessWidget {
  final PetModel pet;
  const _PetDetailsSheet({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image
          Expanded(
            flex: 2,
            child: pet.displayImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: pet.displayImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.inputFill),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.inputFill,
                      child: const Icon(Icons.pets, size: 80, color: AppColors.secondary),
                    ),
                  )
                : Container(
                    color: AppColors.inputFill,
                    child: const Icon(Icons.pets, size: 80, color: AppColors.secondary),
                  ),
          ),
          // Details
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(pet.name, style: AppTypography.h1)),
                      if (pet.vaccinationStatus?['isVaccinated'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified, size: 16, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Vaccinated',
                                style: TextStyle(fontSize: 12, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(pet.breed?.name ?? pet.species?.name ?? '', style: AppTypography.body),
                  const SizedBox(height: 16),
                  // Feature chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FeatureChip(
                        icon: pet.gender == 'MALE' ? Icons.male : Icons.female,
                        label: pet.gender == 'MALE' ? 'Male' : 'Female',
                      ),
                      FeatureChip(
                        icon: Icons.calendar_today,
                        label: pet.ageYears != null
                            ? (pet.ageYears! < 1 ? '< 1 year' : '${pet.ageYears} year${pet.ageYears! > 1 ? 's' : ''}')
                            : 'Unknown age',
                      ),
                      if (pet.weightKg != null)
                        FeatureChip(icon: Icons.monitor_weight, label: '${pet.weightKg} kg'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('About', style: AppTypography.h3),
                  const SizedBox(height: 8),
                  Text(
                    pet.description ?? 'No description available.',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  // Location
                  if (pet.location != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(pet.location!.fullAddress, style: AppTypography.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Pet Code
                  Row(
                    children: [
                      const Icon(Icons.qr_code, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('Pet Code: ${pet.petCode}', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text('Contact Owner'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Interested',
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Interest registered!')),
                            );
                          },
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
    );
  }
}
