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
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PetModel> _filterPets(List<PetModel> pets) {
    if (_searchTerm.isEmpty) return pets;
    final query = _searchTerm.toLowerCase();
    return pets.where((pet) {
      return pet.name.toLowerCase().contains(query) ||
          (pet.breed?.name.toLowerCase().contains(query) ?? false) ||
          (pet.species?.name.toLowerCase().contains(query) ?? false);
    }).toList();
  }

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search pets...',
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
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
                    Text('Failed to load pets: $error', textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => ref.invalidate(myPetsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (pets) {
                final filteredPets = _filterPets(pets);
                if (filteredPets.isEmpty) {
                  return const EmptyState(
                     icon: Icons.pets,
                     title: 'No Pets Found',
                     subtitle: 'Add your first pet to get started',
                  );
                }
                
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isGridView ? _buildGridView(filteredPets) : _buildCarouselView(filteredPets),
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
      itemBuilder: (context, index) => _PetGridCard(
        pet: pets[index],
        onEdit: () => _showAddPetModal(context, pet: pets[index]),
        onDelete: () => _confirmDelete(pets[index].id),
      ),
    );
  }

  Widget _buildCarouselView(List<PetModel> pets) {
    return PageView.builder(
      key: const ValueKey('carousel'),
      controller: PageController(viewportFraction: 0.85),
      itemCount: pets.length,
      itemBuilder: (context, index) => _PetCarouselCard(
        pet: pets[index],
        onEdit: () => _showAddPetModal(context, pet: pets[index]),
        onDelete: () => _confirmDelete(pets[index].id),
      ),
    );
  }

  void _showAddPetModal(BuildContext context, {PetModel? pet}) {
    PetFormSheet.show(context, pet: pet);
  }

  Future<void> _confirmDelete(String petId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: const Text('Are you sure you want to delete this pet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(petCrudProvider.notifier).deletePet(petId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pet deleted successfully'), backgroundColor: AppColors.success),
          );
          ref.invalidate(myPetsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete pet'), backgroundColor: AppColors.error),
          );
        }
      }
    }
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
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: isActive ? AppColors.secondary : Colors.white),
      ),
    );
  }
}

class _PetCarouselCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PetCarouselCard({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/my-pet-details/${pet.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
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
                child: Stack(
                  children: [
                    pet.displayImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolveImageUrl(pet.displayImage),
                            width: double.infinity,
                            fit: BoxFit.fill,
                            placeholder: (_, _) => Container(color: AppColors.inputFill),
                            errorWidget: (_, _, _) => _placeholderImage(),
                          )
                        : _placeholderImage(),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _buildActionMenu(),
                    ),
                  ],
                ),
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

  Widget _buildActionMenu() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PetGridCard({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/my-pet-details/${pet.id}'),
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
              child: Stack(
                children: [
                   pet.displayImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: resolveImageUrl(pet.displayImage),
                      width: double.infinity,
                      fit: BoxFit.fill,
                      placeholder: (_, _) => Container(color: AppColors.inputFill),
                      errorWidget: (_, _, _) => _placeholderImage(),
                    )
                  : _placeholderImage(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildActionMenu(),
                  ),
                ],
              ),
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
      width: double.infinity,
      child: const Center(child: Icon(Icons.pets, size: 40, color: AppColors.secondary)),
    );
  }

  Widget _buildActionMenu() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

