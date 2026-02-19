import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/providers/pet_listing_providers.dart';
import '../../../data/models/models.dart';
import '../../../data/services/pet_listing_service.dart';
import '../../../data/providers/auth_providers.dart';

class PetsPage extends ConsumerStatefulWidget {
  const PetsPage({super.key});

  @override
  ConsumerState<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends ConsumerState<PetsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isGridView = true;
  String? _selectedSpecies;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with gradient
          GradientHeader(
            title: 'Find a Companion',
            subtitle: 'Browse, adopt or buy a pet',
            icon: Icons.pets,
            actions: [
              // View Toggle (only for All Pets tab)
              IconButton(
                icon: Icon(_isGridView ? Icons.view_carousel : Icons.grid_view,
                    color: Colors.white),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              // Cart Icon
              GestureDetector(
                onTap: () => context.push('/cart'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white, size: 20),
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
                            constraints: const BoxConstraints(
                                minWidth: 12, minHeight: 12),
                            child: Text(
                              '${ref.watch(cartProvider).length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            bottom: Column(
              children: [
                // Species filter chips (for All tab)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    children: [
                      _FilterChip(
                          label: 'All',
                          isActive: _selectedSpecies == null,
                          onTap: () =>
                              setState(() => _selectedSpecies = null)),
                      _FilterChip(
                          label: 'Dogs',
                          isActive: _selectedSpecies == 'DOG',
                          onTap: () =>
                              setState(() => _selectedSpecies = 'DOG')),
                      _FilterChip(
                          label: 'Cats',
                          isActive: _selectedSpecies == 'CAT',
                          onTap: () =>
                              setState(() => _selectedSpecies = 'CAT')),
                      _FilterChip(
                          label: 'Birds',
                          isActive: _selectedSpecies == 'BIRD',
                          onTap: () =>
                              setState(() => _selectedSpecies = 'BIRD')),
                      _FilterChip(
                          label: 'Others',
                          isActive: _selectedSpecies == 'OTHER',
                          onTap: () =>
                              setState(() => _selectedSpecies = 'OTHER')),
                    ],
                  ),
                ),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: Colors.white, width: 3)),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'All Pets'),
                    Tab(text: '🏷️ For Sale'),
                    Tab(text: '💜 Adoption'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: All Pets ──
                _AllPetsTab(
                  selectedSpecies: _selectedSpecies,
                  isGridView: _isGridView,
                ),
                // ── Tab 2: For Sale ──
                _ListingsTab(
                  provider: forSaleListingsProvider,
                  onRefresh: () => ref.invalidate(forSaleListingsProvider),
                  emptyTitle: 'No Pets For Sale',
                  emptySubtitle: 'Check back soon for pets available to buy',
                  badgeColor: const Color(0xFF10B981),
                ),
                // ── Tab 3: For Adoption ──
                _ListingsTab(
                  provider: forAdoptionListingsProvider,
                  onRefresh: () => ref.invalidate(forAdoptionListingsProvider),
                  emptyTitle: 'No Pets For Adoption',
                  emptySubtitle:
                      'No pets are available for adoption right now',
                  badgeColor: const Color(0xFF21314C),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── All Pets Tab ────────────────────────────────────────────────────────────
class _AllPetsTab extends ConsumerWidget {
  final String? selectedSpecies;
  final bool isGridView;

  const _AllPetsTab({this.selectedSpecies, required this.isGridView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPetsAsync = ref.watch(allPetsProvider(const PetQueryParams()));

    return allPetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load pets',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(allPetsProvider(const PetQueryParams())),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (result) {
        // Create a mutable copy of the list
        final List<PetModel> pets = List.from(result.data);
        
        final user = ref.watch(currentUserProvider);
        if (user != null) {
          pets.removeWhere((p) => p.ownerId == user.id);
        }

        final filtered = selectedSpecies == null
            ? pets
            : pets.where((p) =>
                    p.speciesId == selectedSpecies ||
                    p.species?.name.toUpperCase() == selectedSpecies)
                .toList();

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.pets,
            title: 'No Pets Found',
            subtitle: 'No pets available in this category',
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isGridView
              ? _buildGridView(context, pets)
              : _buildCarouselView(context, pets),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<PetModel> pets) {
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

  Widget _buildCarouselView(BuildContext context, List<PetModel> pets) {
    return PageView.builder(
      key: const ValueKey('carousel'),
      controller: PageController(viewportFraction: 0.85),
      itemCount: pets.length,
      itemBuilder: (context, index) => _PetCarouselCard(pet: pets[index]),
    );
  }
}

// ─── Listings Tab (For Sale or For Adoption) ─────────────────────────────────
class _ListingsTab extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<PetListingModel>>> provider;
  final VoidCallback onRefresh;
  final String emptyTitle;
  final String emptySubtitle;
  final Color badgeColor;

  const _ListingsTab({
    required this.provider,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(provider);

    return listingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Failed to load listings'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (listings) {
        final user = ref.watch(currentUserProvider);
        final filtered = user == null
            ? listings
            : listings.where((l) => l.ownerId != user.id).toList();
        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.pets,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final listing = filtered[index];
              return _ListingGridCard(
                listing: listing,
                badgeColor: badgeColor,
                onTap: () => context.push('/pet-details/${listing.petId}'),
              );
            },
          ),
        );
      },
    );
  }
}


// ─── Listing Grid Card ────────────────────────────────────────────────────────
class _ListingGridCard extends StatelessWidget {
  final PetListingModel listing;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ListingGridCard({
    required this.listing,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.petImage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with price badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: resolveImageUrl(imageUrl),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _placeholder(Icons.pets),
                          )
                        : _placeholder(Icons.pets),
                  ),
                  // Price Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        listing.isForSale ? listing.displayPrice : 'Free',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.petName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (listing.petSpecies.isNotEmpty)
                      Text(
                        listing.petSpecies,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    const Spacer(),
                    // Owner row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: AppColors.inputFill,
                          backgroundImage: listing.ownerAvatar != null
                              ? CachedNetworkImageProvider(
                                  resolveImageUrl(listing.ownerAvatar!))
                              : null,
                          child: listing.ownerAvatar == null
                              ? const Icon(Icons.person,
                                  size: 10, color: AppColors.textMuted)
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.ownerName,
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _placeholder(IconData icon) {
    return Container(
      color: AppColors.inputFill,
      child: Center(child: Icon(icon, color: AppColors.textMuted, size: 36)),
    );
  }
}

// ─── Filter Chip ─────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? const Color(0xFF21314C)
                : Colors.white,
            fontWeight:
                isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Pet Grid Card (All Pets tab) ────────────────────────────────────────────
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: pet.displayImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resolveImageUrl(pet.displayImage),
                        width: double.infinity,
                        fit: BoxFit.fill,
                        placeholder: (_, _) =>
                            Container(color: AppColors.inputFill),
                        errorWidget: (_, _, _) => _petPlaceholder(),
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
                          child: Text(pet.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Icon(
                          pet.gender == 'MALE'
                              ? Icons.male
                              : Icons.female,
                          size: 16,
                          color: pet.gender == 'MALE'
                              ? AppColors.secondary
                              : Colors.pink,
                        ),
                      ],
                    ),
                    Text(
                      pet.breed?.name ?? pet.species?.name ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          pet.ageYears != null
                              ? (pet.ageYears! < 1
                                  ? '< 1 yr'
                                  : '${pet.ageYears} yr')
                              : '?',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
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
      child: const Center(
          child: Icon(Icons.pets, size: 40, color: AppColors.secondary)),
    );
  }

  void _showPetDetails(BuildContext context) {
    context.push('/pet-details/${pet.id}');
  }
}

// ─── Pet Carousel Card ────────────────────────────────────────────────────────
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              child: pet.displayImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: resolveImageUrl(pet.displayImage),
                      width: double.infinity,
                      fit: BoxFit.fill,
                      placeholder: (_, _) =>
                          Container(color: AppColors.inputFill),
                      errorWidget: (_, _, _) => _petPlaceholder(),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: pet.gender == 'MALE'
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : Colors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pet.gender == 'MALE'
                                  ? Icons.male
                                  : Icons.female,
                              size: 16,
                              color: pet.gender == 'MALE'
                                  ? AppColors.secondary
                                  : Colors.pink,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pet.gender == 'MALE' ? 'Male' : 'Female',
                              style: TextStyle(
                                fontSize: 12,
                                color: pet.gender == 'MALE'
                                    ? AppColors.secondary
                                    : Colors.pink,
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
                            ? (pet.ageYears! < 1
                                ? '< 1 year'
                                : '${pet.ageYears} year${pet.ageYears! > 1 ? 's' : ''}')
                            : 'Unknown',
                      ),
                      const SizedBox(width: 8),
                      if (pet.weightKg != null)
                        _featureChip(
                            Icons.monitor_weight, '${pet.weightKg} kg'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'View Details',
                      onPressed: () =>
                          context.push('/pet-details/${pet.id}'),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _petPlaceholder() {
    return Container(
      color: AppColors.inputFill,
      child:
          const Center(child: Icon(Icons.pets, size: 80, color: AppColors.secondary)),
    );
  }
}
