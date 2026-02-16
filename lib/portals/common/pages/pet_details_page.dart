import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/models/models.dart';
// import '../../../data/providers/mock_data_provider.dart'; // Removing
import '../../../data/providers/pet_providers.dart';
import '../../../data/providers/appointment_providers.dart';

class PetDetailsPage extends ConsumerStatefulWidget {
  final String petId;
  const PetDetailsPage({super.key, required this.petId});

  @override
  ConsumerState<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends ConsumerState<PetDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We mock currentUser for now as we haven't built a full auth provider yet but we need user ID
    // For now, let's assume we can get it from somewhere or just check if pet.ownerId matches a known ID
    // or just rely on 'isMine' logic being: if I can edit it? 
    // Actually, let's use a hardcoded user ID 'user-1' if we don't have a provider, 
    // or better, create a simple provider for current user ID if not exists.
    // I will use a placeholder for currentUser check.
    const currentUserId = 'user-1'; // TODO: Replace with real auth

    final petAsync = ref.watch(petDetailProvider(widget.petId));
    
    return petAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load pet details: $e')),
      ),
      data: (pet) {
        final bool isMine = pet.ownerId == currentUserId;

        if (isMine) {
          return _buildOwnPetView(context, pet);
        } else {
          return _buildMarketplacePetView(context, pet);
        }
      },
    );
  }

  // ============== OWN PET VIEW (TABBED) ==============
  Widget _buildOwnPetView(BuildContext context, PetModel pet) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with Back Button and Tabs
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF21314C)),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Custom Tab Bar Design like "pets_details_profile_tab.png"
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    labelColor: const Color(0xFF21314C),
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'appointments'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(pet),
                _buildAppointmentsTab(pet),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: PrimaryButton(
          label: 'Schedule appointment',
          icon: Icons.north_east,
          onPressed: () => AppointmentFormSheet.show(context),
        ),
      ),
    );
  }

  Widget _buildProfileTab(PetModel pet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet Image Gallery Placeholder
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: (pet.images.isNotEmpty)
                  ? DecorationImage(image: CachedNetworkImageProvider(pet.images.first), fit: BoxFit.cover)
                  : null,
              color: AppColors.inputFill,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text(pet.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(pet.breed?.name ?? 'Unknown Breed', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Info Cards
          Row(
            children: [
              _OwnStatCard(icon: Icons.pets, label: '${pet.ageYears ?? 1} Year'),
              const SizedBox(width: 12),
              _OwnStatCard(icon: Icons.person_outline, label: pet.gender),
              const SizedBox(width: 12),
              _OwnStatCard(icon: Icons.shopping_bag_outlined, label: '${pet.weightKg ?? 0} Kg'),
            ],
          ),
          const SizedBox(height: 24),

          // Health Status
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: const Color(0xFFE8F5E9),
               borderRadius: BorderRadius.circular(15),
             ),
             child: Row(
               children: [
                 const Icon(Icons.medical_services, color: Color(0xFF4CAF50)),
                 const SizedBox(width: 12),
                 const Text('vaccinated', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 18)),
                 const Spacer(),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Location', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                     Text(pet.location?.name ?? 'Unknown', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ],
             ),
          ),
          const SizedBox(height: 32),

          Text('About', style: AppTypography.h2),
          const SizedBox(height: 12),
          Text(
            pet.description ?? 'No description available.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          Text('Medical Status', style: AppTypography.h2),
          const SizedBox(height: 12),
          Text(
            pet.healthSummary ?? 'Healthy and active.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_copy_outlined),
            label: const Text('view medical issue', style: TextStyle(decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab(PetModel pet) {
     final appointmentsAsync = ref.watch(myAppointmentsProvider(null));

     return appointmentsAsync.when(
       loading: () => const Center(child: CircularProgressIndicator()),
       error: (e, _) => Center(child: Text('Error: $e')),
       data: (paginated) {
         final appointments = paginated.data.where((a) => a.petId == pet.id).toList();

         return ListView(
           padding: const EdgeInsets.all(24),
           children: [
             const Text('New Pet', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
             const Text('your pet appointments', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
             const SizedBox(height: 24),
             
             if (appointments.isEmpty)
               const Center(child: Text('No upcoming appointments.'))
             else
               ...appointments.map((apt) => Container(
                 margin: const EdgeInsets.only(bottom: 20),
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(20),
                   boxShadow: AppTheme.cardShadow,
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                         const SizedBox(width: 8),
                         const Text('your appointment was confirmed', style: TextStyle(color: Color(0xFF4CAF50))),
                       ],
                     ),
                     const SizedBox(height: 16),
                     const Text('Appointment details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                     Row(
                       children: [
                         if (apt.provider != null) ...[
                           CircleAvatar(
                           radius: 15,
                           backgroundImage: apt.provider!.avatarUrl != null ? CachedNetworkImageProvider(apt.provider!.avatarUrl!) : null,
                         ),
                         const SizedBox(width: 10),
                         Text('with ${apt.provider!.fullName}', style: const TextStyle(color: AppColors.textSecondary)),
                         ]
                       ],
                     ),
                     const SizedBox(height: 12),
                     Text(apt.provider?.businessName ?? 'Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     Row(
                       children: [
                         const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                         const SizedBox(width: 4),
                         const Text('Kicukiro, Sonatube', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                       ],
                     ),
                     const SizedBox(height: 20),
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: AppColors.inputFill,
                         borderRadius: BorderRadius.circular(10),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.calendar_month, color: AppColors.secondary),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Text('Date and Time', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                 Text('${apt.scheduledAt.day}/${apt.scheduledAt.month}/${apt.scheduledAt.year} . ${apt.scheduledTime ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                               ],
                             ),
                           ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 24),
                     Row(
                       children: [
                         Expanded(
                           child: OutlinedButton(
                             onPressed: () {},
                             style: OutlinedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: const Text('Reschedule'),
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: ElevatedButton(
                             onPressed: () {},
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFFFF4444),
                               padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: const Text('cancel', style: TextStyle(color: Colors.white)),
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
               )),
           ],
         );
       }
     );
  }

  // ============== MARKETPLACE PET VIEW ==============
  Widget _buildMarketplacePetView(BuildContext context, PetModel pet) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Elegant Header with Curved Bottom
          SliverAppBar(
            expandedHeight: 400,
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
                  pet.images.isNotEmpty
                      ? CachedNetworkImage(imageUrl: pet.images.first, fit: BoxFit.cover)
                      : Container(color: AppColors.inputFill),
                  // Pagination dots indicator simulation
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == 1 ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == 1 ? Colors.white : Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      )),
                    ),
                  ),
                  // Expand Button
                  Positioned(
                    bottom: 40,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fullscreen, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pet.name, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                              Text(pet.breed?.name ?? 'Unknown Breed', style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(pet.listingType == 'FOR_SALE' ? 'For purchase' : 'For adoption', 
                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(pet.location?.name ?? 'Unknown', style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('view on map', style: TextStyle(color: AppColors.secondary, decoration: TextDecoration.underline)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Feature Stats Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MarketStatCard(label: 'sex', value: pet.gender, color: const Color(0xFFD3EAF2)),
                        _MarketStatCard(label: 'Age', value: '${pet.ageYears ?? 0} year', color: const Color(0xFFD7C7F2)),
                        _MarketStatCard(label: 'weight', value: '${pet.weightKg ?? 0} kg', color: const Color(0xFFF2D3DC)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Owner Section
                    if (pet.owner != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: pet.owner!.avatarUrl != null ? CachedNetworkImageProvider(pet.owner!.avatarUrl!) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pet.owner!.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const Text('Owner', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_outline, color: AppColors.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],

                    Text('Summary', style: AppTypography.h2),
                    const SizedBox(height: 12),
                    Text(
                      pet.description ?? "No description provided.",
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 12),
                        const Text('Vaccinated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Text('Delivery: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const Text('Pick -Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (pet.listingType == 'FOR_SALE')
                      Row(
                        children: [
                          const Text('Price: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                          Text('${pet.price?.toInt() ?? 0} Frw', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: pet.listingType == 'FOR_SALE'
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addPet(pet);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart!'), backgroundColor: AppColors.success),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Add to cart', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addPet(pet);
                        context.push('/cart');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21314C),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            : PrimaryButton(
                label: 'Adopt Now',
                onPressed: () {},
              ),
      ),
    );
  }
}

class _OwnStatCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OwnStatCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MarketStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MarketStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 80) / 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
