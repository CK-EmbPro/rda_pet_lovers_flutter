import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/mock_data_provider.dart';

class PetDetailsPage extends ConsumerWidget {
  final String petId;
  const PetDetailsPage({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final browsablePets = ref.watch(browsablePetsProvider);
    final myPets = ref.watch(myPetsProvider);
    
    // Find pet in either browsable or my pets
    PetModel? pet;
    try {
      pet = myPets.firstWhere((p) => p.id == petId);
    } catch (_) {
      try {
        pet = browsablePets.firstWhere((p) => p.id == petId);
      } catch (_) {
        // Handle not found
      }
    }

    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pet Not Found')),
        body: const Center(child: Text('The requested pet could not be found.')),
      );
    }

    final bool isMine = pet.ownerId == user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header Container with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: const Color(0xFF21314C),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  pet.displayImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: pet.displayImage,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.inputFill,
                          child: const Icon(Icons.pets, size: 100, color: AppColors.secondary),
                        ),
                  // Overlay for better text visibility if needed
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pet.name, style: AppTypography.h1),
                              const SizedBox(height: 4),
                              Text(
                                '${pet.breed?.name ?? pet.species?.name ?? "Unknown Breed"} • ${pet.gender}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
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
                                Text('Vaccinated', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCard(
                          label: 'Age',
                          value: pet.ageYears != null ? '${pet.ageYears} yrs' : 'N/A',
                          icon: Icons.calendar_today_outlined,
                        ),
                        _StatCard(
                          label: 'Weight',
                          value: pet.weightKg != null ? '${pet.weightKg} kg' : 'N/A',
                          icon: Icons.monitor_weight_outlined,
                        ),
                        _StatCard(
                          label: 'Breed',
                          value: pet.breed?.name ?? 'Mixed',
                          icon: Icons.pets_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Description
                    Text('About ${pet.name}', style: AppTypography.h3),
                    const SizedBox(height: 12),
                    Text(
                      pet.description ?? 'No description provided for this pet yet.',
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Context Specific sections
                    if (isMine) ...[
                      _buildOwnerSection(context, pet),
                    ] else ...[
                      _buildMarketplaceSection(context, pet),
                    ],

                    const SizedBox(height: 100), // Space for bottom actions
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(context, ref, isMine, pet),
    );
  }

  Widget _buildOwnerSection(BuildContext context, PetModel pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health History', style: AppTypography.h3),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              _HistoryItem(
                title: 'Last Vaccination',
                subtitle: pet.vaccinationStatus?['lastVaccinationDate'] ?? 'Unknown',
                icon: Icons.medical_services_outlined,
              ),
              const Divider(height: 24),
              _HistoryItem(
                title: 'Medical Checkup',
                subtitle: 'Healthy - Jan 2026',
                icon: Icons.monitor_heart_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketplaceSection(BuildContext context, PetModel pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Owner Info', style: AppTypography.h3),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.inputFill,
                backgroundImage: pet.owner?.avatarUrl != null ? CachedNetworkImageProvider(pet.owner!.avatarUrl!) : null,
                child: pet.owner?.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.owner?.fullName ?? 'Anonymous Lover', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(pet.location?.fullAddress ?? 'Kigali, Rwanda', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.secondary),
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (pet.listingType != 'NOT_LISTED') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pet.listingType == 'FOR_SALE' 
                      ? 'This pet is available for sale. You can proceed to buy or add to your cart.'
                      : 'This pet is available for donation. Contact the owner to express interest.',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, bool isMine, PetModel pet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: isMine
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => AppointmentFormSheet.show(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Edit Profile',
                    onPressed: () {},
                  ),
                ),
              ],
            )
          : Row(
              children: [
                if (pet.listingType == 'FOR_SALE') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addPet(pet);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart!'), backgroundColor: AppColors.success),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Buy Now',
                      onPressed: () {
                        ref.read(cartProvider.notifier).addPet(pet);
                        context.push('/cart');
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: PrimaryButton(
                      label: 'Express Interest',
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Interest registered! The owner will notify you.')),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HistoryItem({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
