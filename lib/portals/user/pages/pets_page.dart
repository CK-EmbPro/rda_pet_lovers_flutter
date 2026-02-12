import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/services/pet_service.dart';
import '../../../data/models/models.dart';
import '../../pet_owner/widgets/pet_form_sheet.dart';

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
    final allPetsAsync = ref.watch(allPetsProvider(const PetQueryParams()));
    

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
                      'My Pets',
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
                        const SizedBox(width: 8),
                        _ViewToggle(
                          icon: Icons.add,
                          isActive: false,
                          onTap: () => _showAddPetModal(context),
                        ),
                        const SizedBox(width: 8),
                        // Cart Icon
                        GestureDetector(
                          onTap: () => context.push('/cart'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                                if (ref.watch(cartProvider).isNotEmpty)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                      child: Text(
                                        '${ref.watch(cartProvider).length}',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Species Filter - static species list (TODO: fetch from API when species endpoint available)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSpecies = null),
                    child: _FilterChip(label: 'All', isSelected: _selectedSpecies == null),
                  ),
                ),
                for (final entry in {'DOG': '🐕 Dogs', 'CAT': '🐈 Cats', 'BIRD': '🐦 Birds', 'RABBIT': '🐇 Rabbits'}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSpecies = entry.key),
                      child: _FilterChip(label: entry.value, isSelected: _selectedSpecies == entry.key),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: allPetsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load pets: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(allPetsProvider(const PetQueryParams())),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (result) {
                final pets = _selectedSpecies == null
                    ? result.data
                    : result.data.where((p) => p.speciesId == _selectedSpecies || p.species?.name?.toUpperCase() == _selectedSpecies).toList();
                return pets.isEmpty
                    ? const EmptyState(
                        icon: Icons.pets,
                        title: 'No Pets Found',
                        subtitle: 'No pets available in this category',
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isGridView ? _buildGridView(pets) : _buildCarouselView(pets),
                      );
              },
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

  void _showAddPetModal(BuildContext context) {
    PetFormSheet.show(context);
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
        color: isSelected ? const Color(0xFF21314C) : AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
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
    context.push('/pet-details/${pet.id}');
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
                      Expanded(
                        child: Text(
                          pet.name,
                          style: AppTypography.h2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                      _featureChip(
                        Icons.calendar_today,
                        pet.ageYears != null
                            ? (pet.ageYears! < 1 ? '< 1 year' : '${pet.ageYears} year${pet.ageYears! > 1 ? 's' : ''}')
                            : 'Unknown',
                      ),
                      const SizedBox(width: 8),
                      if (pet.weightKg != null)
                        _featureChip(Icons.monitor_weight, '${pet.weightKg} kg'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'View Details',
                      onPressed: () => context.push('/pet-details/${pet.id}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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



