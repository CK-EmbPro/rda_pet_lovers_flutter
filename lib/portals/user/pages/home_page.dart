import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/providers/cart_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/filter_sheet.dart';
import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';
import '../user_portal.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final categories = ref.watch(categoriesProvider);
    final shops = ref.watch(shopsProvider);
    final pets = ref.watch(browsablePetsProvider);
    final services = ref.watch(servicesProvider);

    // Split pets by listing type
    final petsForSale = pets.where((p) => p.listingType == 'FOR_SALE').toList();
    final petsForDonation = pets.where((p) => p.listingType == 'FOR_DONATION').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with notification and profile
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey, ${user?.fullName.split(' ').first ?? 'Guest'}',
                          style: AppTypography.h2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getGreeting(),
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Cart Icon
                        GestureDetector(
                          onTap: () => context.push('/cart'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                const Icon(Icons.shopping_cart_outlined, color: AppColors.textSecondary),
                                if (ref.watch(cartProvider).isNotEmpty)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
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
                        const SizedBox(width: 12),
                        // Notification Icon
                        GestureDetector(
                          onTap: () => NotificationsSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile Icon - Links to Profile Page
                        GestureDetector(
                          onTap: () {
                            // Navigate to profile tab
                            final portal = context.findAncestorStateOfType<UserPortalState>();
                            portal?.navigateToTab(5);
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.inputFill,
                            backgroundImage: user?.avatarUrl != null
                                ? CachedNetworkImageProvider(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? const Icon(Icons.person, color: AppColors.textSecondary)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar with Filter Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search pets, services, shops...',
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => FilterSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Categories with active highlighting
              _buildCategoriesSection(categories),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context, ref),
              const SizedBox(height: 24),

              // Shops Section
              _buildShopsSection(context, shops),
              const SizedBox(height: 24),

              // Products Section
              _buildProductsSection(context, ref),
              const SizedBox(height: 24),

              // Being Sold Section
              if (petsForSale.isNotEmpty) ...[
                _buildPetsSectionHeader(context, 'Being Sold', () {
                  final portal = context.findAncestorStateOfType<UserPortalState>();
                  portal?.navigateToTab(3);
                }),
                _buildPetsGrid(petsForSale.take(4).toList()),
                const SizedBox(height: 24),
              ],

              // Being Donated Section
              if (petsForDonation.isNotEmpty) ...[
                _buildPetsSectionHeader(context, 'Being Donated', () {
                  final portal = context.findAncestorStateOfType<UserPortalState>();
                  portal?.navigateToTab(3);
                }),
                _buildPetsGrid(petsForDonation.take(4).toList()),
                const SizedBox(height: 24),
              ],

              // Available Services Section (Moved to bottom)
              _buildServicesSection(context, services),
              const SizedBox(height: 24),

              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<dynamic> categories) {
    return _CategoriesWidget(categories: categories);
  }


  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add pet',
                color: AppColors.secondary,
                onTap: () => _showAddPetModal(context),
              ),
              const SizedBox(width: 12),
              _QuickActionButton(
                icon: Icons.compare_arrows,
                label: 'Mate Check',
                color: AppColors.success,
                onTap: () => _showMateCheckModal(context, ref),
              ),
              const SizedBox(width: 12),
              _QuickActionButton(
                icon: Icons.calendar_today,
                label: 'Book Service',
                color: Colors.orange,
                onTap: () {
                  final portal = context.findAncestorStateOfType<UserPortalState>();
                  portal?.navigateToTab(1);
                },
              ),
              const SizedBox(width: 12),
              _QuickActionButton(
                icon: Icons.shopping_bag_outlined,
                label: 'Shop',
                color: Colors.green,
                onTap: () {
                  final portal = context.findAncestorStateOfType<UserPortalState>();
                  portal?.navigateToTab(2);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trending Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {
                  final portal = context.findAncestorStateOfType<UserPortalState>();
                  portal?.navigateToTab(2);
                },
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => context.push('/product-details/${product.id}'),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: product.mainImage != null
                              ? CachedNetworkImage(
                                  imageUrl: product.mainImage!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(color: AppColors.inputFill),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${product.effectivePrice.toInt()} RWF',
                              style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context, List<dynamic> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {
                  final portal = context.findAncestorStateOfType<UserPortalState>();
                  portal?.navigateToTab(1);
                },
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: services.take(5).length,
            itemBuilder: (context, index) {
              final service = services[index];
              return GestureDetector(
                onTap: () => context.push('/service-details/${service.id}'),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.medical_services, color: AppColors.secondary, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${service.fee.toInt()} RWF',
                        style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShopsSection(BuildContext context, List<dynamic> shops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shops Near You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {
                  final portal = context.findAncestorStateOfType<UserPortalState>();
                  portal?.navigateToTab(2);
                },
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return GestureDetector(
                onTap: () => context.push('/shop-details/${shop.id}'),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.inputFill,
                            backgroundImage: shop.logoUrl != null
                                ? CachedNetworkImageProvider(shop.logoUrl!)
                                : null,
                            child: shop.logoUrl == null
                                ? const Icon(Icons.store, color: AppColors.secondary)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              shop.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text('${shop.rating ?? 4.5}', style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Text('${shop.productCount} items', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPetsSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsGrid(List<PetModel> pets) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return _PetCard(pet: pet);
      },
    );
  }

  void _showAddPetModal(BuildContext context) {
    XFile? profileImage;
    List<XFile> galleryImages = [];
    DateTime? selectedBirthDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
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
                      // Profile Photo Section
                      const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final image = await _pickImage(context, ImageSource.gallery);
                            if (image != null) setModalState(() => profileImage = image);
                          },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.secondary, width: 2),
                              image: profileImage != null
                                  ? DecorationImage(image: FileImage(File(profileImage!.path)), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: profileImage == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 30, color: AppColors.secondary),
                                      Text('Add Profile', style: TextStyle(fontSize: 10, color: AppColors.secondary)),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Gallery Photos Section
                      const Text('Gallery Photos (Multiple)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final List<XFile> images = await ImagePicker().pickMultiImage();
                                if (images.isNotEmpty) {
                                  setModalState(() => galleryImages.addAll(images));
                                }
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.secondary),
                              ),
                            ),
                            ...galleryImages.map((img) => Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(left: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    image: DecorationImage(image: FileImage(File(img.path)), fit: BoxFit.cover),
                                  ),
                                )),
                          ],
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
                          Expanded(child: _buildDropdownField('Gender', 'MALE / FEMALE')),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().subtract(const Duration(days: 365)),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) setModalState(() => selectedBirthDate = date);
                              },
                              child: AbsorbPointer(
                                child: AppTextField(
                                  label: 'Birth Date',
                                  hint: selectedBirthDate != null 
                                      ? "${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}"
                                      : 'Select date',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: const AppTextField(label: 'Weight (kg)', hint: 'e.g. 15', keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDropdownField('Nationality', 'Select nationality')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField('Listing Type', 'Personal / Selling / Donation'),
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
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<XFile?> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(source: source);
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

  void _showMateCheckModal(BuildContext context, WidgetRef ref) {
    final myPets = ref.read(myPetsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Mate Compatibility Check', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Check if two pets are compatible for mating by comparing their parents and grandparents.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Your Pet Code',
              hint: myPets.isNotEmpty ? myPets.first.petCode : 'PET-XXX-XXX',
              prefixIcon: Icons.pets,
            ),
            const SizedBox(height: 16),
            const AppTextField(label: 'Partner Pet Code', hint: 'Enter partner pet code', prefixIcon: Icons.pets),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Check Compatibility',
              onPressed: () {
                Navigator.pop(context);
                _showCompatibilityResult(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompatibilityResult(BuildContext context, bool isCompatible) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompatible ? Icons.check_circle : Icons.cancel,
              size: 60,
              color: isCompatible ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isCompatible ? 'Compatible!' : 'Not Compatible',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isCompatible
                  ? 'These pets have no matching parents or grandparents and are safe for mating.'
                  : 'These pets share common ancestors and should not be mated.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera capture
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery picker
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  const _PetCard({required this.pet});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: pet.displayImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: pet.displayImage,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.inputFill,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.inputFill,
                                child: const Icon(Icons.pets, size: 40, color: AppColors.secondary),
                              ),
                            )
                          : Container(
                              color: AppColors.inputFill,
                              child: const Icon(Icons.pets, size: 40, color: AppColors.secondary),
                            ),
                    ),
                  ),
                  // Listing type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pet.listingType == 'FOR_SALE' ? AppColors.secondary : Colors.pink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pet.listingType == 'FOR_SALE' ? 'Sale' : 'Donate',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pet Info
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
                          child: Text(
                            pet.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          pet.gender == 'MALE' ? Icons.male : Icons.female,
                          size: 16,
                          color: pet.gender == 'MALE' ? AppColors.secondary : Colors.pink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pet.breed?.name ?? pet.species?.name ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          pet.ageYears != null
                              ? (pet.ageYears! < 1 ? '< 1 year' : '${pet.ageYears} year${pet.ageYears! > 1 ? 's' : ''}')
                              : 'Unknown age',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        if (pet.price != null && pet.price! > 0)
                          Text(
                            '${pet.price!.toInt()} RWF',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
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
}

class _CategoriesWidget extends StatefulWidget {
  final List<dynamic> categories;
  const _CategoriesWidget({required this.categories});

  @override
  State<_CategoriesWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<_CategoriesWidget> {
  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final cat = widget.categories[index];
              final isActive = index == activeIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    activeIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF21314C) : Colors.white,
                          border: Border.all(
                            color: isActive ? const Color(0xFF21314C) : AppColors.inputFill,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            cat.icon ?? '🐾',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? const Color(0xFF21314C) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
