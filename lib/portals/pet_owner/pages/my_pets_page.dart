import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/mock_data_provider.dart';
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
    final myPets = ref.watch(myPetsProvider);

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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search pets...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: myPets.isEmpty
                ? const EmptyState(
                    icon: Icons.pets,
                    title: 'No Pets Found',
                    subtitle: 'Register your first pet to see it here!',
                  )
                : _isGridView 
                    ? _buildGridView(myPets) 
                    : _buildSliderView(myPets),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.secondary, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: AppColors.secondary),
                              const SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AppTextField(label: 'Pet Name', hint: 'e.g. Buddy'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdownField('Species', 'Select species')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdownField('Breed', 'Select breed')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdownField('Gender', 'Select gender')),
                        const SizedBox(width: 16),
                        Expanded(child: const AppTextField(label: 'Age', hint: 'e.g. 2 years')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const AppTextField(label: 'Weight (kg)', hint: 'e.g. 15'),
                    const SizedBox(height: 16),
                    const AppTextField(label: 'Location', hint: 'e.g. Kicukiro, Kigali'),
                    const SizedBox(height: 16),
                    const AppTextField(
                      label: 'Health Summary',
                      hint: 'e.g. Vaccinated, healthy...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const AppTextField(
                      label: 'Description',
                      hint: 'Tell us more about your pet...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Register Pet',
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pet registered successfully!'), backgroundColor: AppColors.success),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String hint) {
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
              items: [],
              onChanged: (val) {},
            ),
          ),
        ),
      ],
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
                      Text(pet.name, style: AppTypography.h2),
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
                  Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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

