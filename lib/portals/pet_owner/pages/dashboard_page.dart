import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../core/widgets/filter_sheet.dart';
import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../core/widgets/all_appointments_sheet.dart';
import '../../../core/widgets/all_orders_sheet.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';
import '../pet_owner_portal.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final services = ref.watch(servicesProvider);
    final appointments = ref.watch(myAppointmentsProvider);
    final shops = ref.watch(shopsProvider);
    final browsablePets = ref.watch(browsablePetsProvider);

    // Split browsable pets by listing type
    final petsForSale = browsablePets.where((p) => p.listingType == 'FOR_SALE').toList();
    final petsForDonation = browsablePets.where((p) => p.listingType == 'FOR_DONATION').toList();

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
                        Text('Welcome Back,', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text(user?.fullName ?? 'Pet Owner', style: AppTypography.h2),
                      ],
                    ),
                    Row(
                      children: [
                        // Cart Icon
                        GestureDetector(
                          onTap: () {
                            final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                            portal?.navigateToTab(4);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final cartCount = ref.watch(cartProvider).length;
                                return Stack(
                                  children: [
                                    const Icon(Icons.shopping_cart_outlined, color: AppColors.textSecondary),
                                    if (cartCount > 0)
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
                                            '$cartCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
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
                            final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
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

              // Search Bar with Filter
              _buildSearchBar(context),
              const SizedBox(height: 24),

              // Categories Section
              _buildCategoriesSection(ref),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context, ref),
              const SizedBox(height: 24),

              // Upcoming Appointments
              if (appointments.isNotEmpty) ...[
                _buildUpcomingAppointmentsHeader(context),
                ...appointments.take(2).map((apt) => _AppointmentCard(appointment: apt)),
                const SizedBox(height: 24),
              ],

              // Recent Orders
              _buildRecentOrdersSection(context),
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
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                  portal?.navigateToTab(2);
                }),
                _buildPetsHorizontalList(petsForSale.take(5).toList()),
                const SizedBox(height: 24),
              ],

              // Being Donated Section
              if (petsForDonation.isNotEmpty) ...[
                _buildPetsSectionHeader(context, 'Being Donated', () {
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                  portal?.navigateToTab(2);
                }),
                _buildPetsHorizontalList(petsForDonation.take(5).toList()),
                const SizedBox(height: 24),
              ],

              // Available Services Section (Moved to bottom)
              _buildServicesSection(context, services),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
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
    );
  }

  Widget _buildCategoriesSection(WidgetRef ref) {
    final categories = ref.watch(speciesProvider);
    return _CategoriesWidget(categories: categories);
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add pet',
                color: AppColors.secondary,
                onTap: () => _showAddPetModal(context),
              ),
              _QuickActionButton(
                icon: Icons.favorite_outline,
                label: 'Donate',
                color: Colors.pink,
                onTap: () {},
              ),
              _QuickActionButton(
                icon: Icons.sell_outlined,
                label: 'Sell',
                color: Colors.green,
                onTap: () {},
              ),
              _QuickActionButton(icon: Icons.compare_arrows, label: 'Mate Check', color: AppColors.success, onTap: () => _showMateCheckModal(context, ref)),
              _QuickActionButton(
                icon: Icons.calendar_today,
                label: 'Book Service',
                color: Colors.orange,
                onTap: () {
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                  portal?.navigateToTab(2);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointmentsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Upcoming Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: () => AllAppointmentsSheet.show(context),
            child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context) {
    // Mock recent orders for the pet owner
    final mockRecentOrders = [
      {'product': 'Premium Dog Food', 'shop': 'Pet Paradise', 'total': 45000, 'status': 'delivered', 'date': '2 days ago'},
      {'product': 'Cat Treats Pack', 'shop': 'Happy Paws', 'total': 12000, 'status': 'shipped', 'date': '5 days ago'},
      {'product': 'Pet Shampoo', 'shop': 'Pet Care Plus', 'total': 8500, 'status': 'pending', 'date': '1 week ago'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => AllOrdersSheet.show(context),
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: mockRecentOrders.length,
          itemBuilder: (context, index) {
            final order = mockRecentOrders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['product'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${order['shop']} • ${order['total']} RWF', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(order['date'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  _buildOrderStatusBadge(order['status'] as String),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'delivered':
        color = AppColors.success;
        break;
      case 'shipped':
        color = AppColors.secondary;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildShopsSection(BuildContext context, List<ShopModel> shops) {
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
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
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
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                  portal?.navigateToTab(2);
                },
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 184,
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

  Widget _buildServicesSection(BuildContext context, List<ServiceModel> services) {
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
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                  portal?.navigateToTab(2);
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
                        child: const Icon(Icons.medical_services, color: AppColors.secondary, size: 20),
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

  Widget _buildPetsHorizontalList(List<PetModel> pets) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: _PetDashboardCard(pet: pet),
          );
        },
      ),
    );
  }
}

class _PetDashboardCard extends StatelessWidget {
  final PetModel pet;
  const _PetDashboardCard({required this.pet});

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
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: pet.displayImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: pet.displayImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(color: AppColors.inputFill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(pet.breed?.name ?? pet.species?.name ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  if (pet.price != null && pet.price! > 0)
                    Text('${pet.price!.toInt()} RWF', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
            backgroundImage: appointment.provider?.avatarUrl != null
                ? CachedNetworkImageProvider(appointment.provider!.avatarUrl!)
                : null,
            child: appointment.provider?.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.provider?.fullName ?? 'Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(appointment.service?.name ?? 'Service', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${appointment.scheduledAt.day}/${appointment.scheduledAt.month} at ${appointment.scheduledAt.hour}:${appointment.scheduledAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(label: appointment.displayStatus, isPositive: appointment.isConfirmed),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/service-details/${service.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
              backgroundImage: service.provider?.avatarUrl != null
                  ? CachedNetworkImageProvider(service.provider!.avatarUrl!)
                  : null,
              child: service.provider?.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.provider?.fullName ?? 'Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(service.displayServiceType, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const StatusBadge(label: 'Available', isPositive: true),
          ],
        ),
      ),
    );
  }
}
