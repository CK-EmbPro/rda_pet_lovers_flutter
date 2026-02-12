import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../widgets/pet_form_sheet.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/models/models.dart';

class MyPetsPage extends ConsumerStatefulWidget {
  const MyPetsPage({super.key});

  @override
  ConsumerState<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends ConsumerState<MyPetsPage> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final myPetsAsync = ref.watch(myPetsProvider);

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
                    const Text('My Pets', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        _ViewToggle(
                          icon: Icons.view_carousel,
                          isActive: !_isGridView,
                          onTap: () => setState(() => _isGridView = false),
                        ),
                        const SizedBox(width: 8),
                        _ViewToggle(
                          icon: Icons.grid_view,
                          isActive: _isGridView,
                          onTap: () => setState(() => _isGridView = true),
                        ),
                        const SizedBox(width: 8),
                        _ViewToggle(
                          icon: Icons.add,
                          isActive: false,
                          onTap: () => _showAddPetModal(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search
                // Search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const TextField(
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search pets...',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: AppColors.textSecondary),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: myPetsAsync.when(
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
                      onPressed: () => ref.invalidate(myPetsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (myPets) => myPets.isEmpty
                  ? const EmptyState(
                      icon: Icons.pets,
                      title: 'No Pets Found',
                      subtitle: 'Register your first pet to see it here!',
                    )
                  : _isGridView
                      ? _buildGridView(myPets)
                      : _buildSliderView(myPets),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderView(List<PetModel> pets) {
    return PageView.builder(
      controller: PageController(viewportFraction: 0.85),
      itemCount: pets.length,
      itemBuilder: (context, index) => _PetDetailCard(pet: pets[index]),
    );
  }

  Widget _buildGridView(List<PetModel> pets) {
    return GridView.builder(
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

class _PetDetailCard extends StatelessWidget {
  final PetModel pet;
  const _PetDetailCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pet-details/${pet.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
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
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
          ),
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
                      Icon(
                        pet.gender == 'MALE' ? Icons.male : Icons.female,
                        color: pet.gender == 'MALE' ? AppColors.secondary : Colors.pink,
                      ),
                    ],
                  ),
                  Text(pet.breed?.name ?? pet.species?.name ?? '', style: AppTypography.bodySmall),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FeatureChip(
                        icon: Icons.calendar_today,
                        label: pet.ageYears != null ? '${pet.ageYears} years' : 'Unknown age',
                      ),
                      FeatureChip(icon: Icons.pets, label: pet.species?.name ?? 'Pet'),
                      FeatureChip(icon: Icons.qr_code, label: pet.petCode),
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

  Widget _placeholderImage() {
    return Container(
      color: AppColors.inputFill,
      child: const Center(child: Icon(Icons.pets, size: 80, color: AppColors.secondary)),
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final PetModel pet;
  const _PetGridCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pet-details/${pet.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
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
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pet.breed?.name ?? pet.species?.name ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: pet.vaccinationStatus?['isVaccinated'] == true ? 'Vaccinated' : 'Unvaccinated',
                    isPositive: pet.vaccinationStatus?['isVaccinated'] == true,
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

  Widget _placeholderImage() {
    return Container(
      color: AppColors.inputFill,
      child: const Center(child: Icon(Icons.pets, size: 40, color: AppColors.secondary)),
    );
  }
}

