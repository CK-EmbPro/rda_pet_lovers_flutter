import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../core/widgets/all_appointments_sheet.dart';
import '../../../core/widgets/all_orders_sheet.dart';
import '../../../core/widgets/filter_sheet.dart';
import '../../pet_owner/widgets/pet_form_sheet.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/providers/category_providers.dart';
import '../../../data/providers/shop_providers.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/providers/product_providers.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/providers/appointment_providers.dart';
import '../../../data/providers/order_providers.dart'; 
import '../../../data/models/models.dart';
import '../../../data/services/pet_service.dart';
import '../user_portal.dart'; // For navigation
import '../../../core/utils/toast_utils.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _soldSectionKey = GlobalKey();
  final GlobalKey _donatedSectionKey = GlobalKey();
  
  // State variable for filtering
  String? _selectedCategoryId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.1, // Slight offset from top
      ).then((_) {
        // Optional: Flash or highlight effect could go here
      });
    } else {
      // If the section is not visible (e.g. no pets in that category), show a toast
      ToastUtils.showInfo(this.context, 'No pets available in this category at the moment.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null;
    
    // Filter State (Local to this build if we want to rebuild on change, but usually better in State class)
    // Since we're in build, we use the state variable _selectedCategoryId defined in _HomePageState
    
    // Async Providers with Filtering
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final shopsAsync = ref.watch(allShopsProvider(const ShopQueryParams(limit: 5)));
    
    // Filter Products and Services by selected Category
    final petsAsync = ref.watch(allPetsProvider(const PetQueryParams(limit: 10)));
    final servicesAsync = ref.watch(allServicesProvider(ServiceQueryParams(limit: 5, categoryId: _selectedCategoryId)));
    final productsAsync = ref.watch(allProductsProvider(ProductQueryParams(limit: 10, categoryId: _selectedCategoryId)));
    
    // User-specific data (skip for guests)
    final appointmentsAsync = isGuest 
        ? const AsyncValue<PaginatedResponse<AppointmentModel>>.data(PaginatedResponse(data: [], page: 1, limit: 5, total: 0, totalPages: 0))
        : ref.watch(myAppointmentsProvider(null));
    final ordersAsync = isGuest 
        ? const AsyncValue<List<OrderModel>>.data([]) 
        : ref.watch(myOrdersProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
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
                        Text(user?.fullName.split(' ').first ?? 'Guest', style: AppTypography.h2),
                      ],
                    ),
                    Row(
                      children: [
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
                            portal?.navigateToTab(4); // Profile is index 4
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

              // Search Bar with Filter Icon (Updated Style)
              _buildSearchBar(context),
              const SizedBox(height: 24),

              // Categories Section (Interactive)
              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (categories) => _CategoriesWidget(
                  categories: categories,
                  selectedId: _selectedCategoryId,
                  onCategorySelected: (id) {
                    setState(() {
                      if (_selectedCategoryId == id) {
                        _selectedCategoryId = null; // Toggle off
                      } else {
                        _selectedCategoryId = id;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Upcoming Appointments
              if (!isGuest)
                appointmentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (PaginatedResponse<AppointmentModel> response) {
                    final List<AppointmentModel> appointments = response.data;
                    if (appointments.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUpcomingAppointmentsHeader(context),
                        ...appointments.take(2).map<Widget>((apt) => _AppointmentCard(appointment: apt)),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                ),

              // Recent Orders
              if (!isGuest)
                 ordersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (List<OrderModel> orders) {
                    if (orders.isEmpty) return const SizedBox.shrink();
                    return _buildRecentOrdersSection(context, orders);
                  }
                ),
              if (!isGuest) const SizedBox(height: 24),

              // Shops Section (Increased width)
              shopsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (PaginatedResponse<ShopModel> response) {
                  return _buildShopsSection(context, response.data);
                },
              ),
              const SizedBox(height: 24),

              // Products Section (Increased width)
              productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (PaginatedResponse<ProductModel> response) {
                  return _buildProductsSection(context, response.data);
                },
              ),
              const SizedBox(height: 24),

              // Pets Section (Sale/Donation) using AsyncValue
              petsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (PaginatedResponse<PetModel> response) {
                  final List<PetModel> pets = response.data;
                  final petsForSale = pets.where((p) => p.listingType == 'FOR_SALE').toList();
                  final petsForDonation = pets.where((p) => p.listingType == 'FOR_DONATION').toList();
                  
                  return Column(
                    children: [
                       // Being Sold Section
                      if (petsForSale.isNotEmpty) ...[
                        Container(
                          key: _soldSectionKey,
                          child: Column(
                            children: [
                              _buildPetsSectionHeader(context, 'Being Sold', () {
                                final portal = context.findAncestorStateOfType<UserPortalState>();
                                portal?.navigateToTab(2); 
                              }),
                              _buildPetsHorizontalList(context, petsForSale.take(5).toList()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Being Donated Section
                      if (petsForDonation.isNotEmpty) ...[
                        Container(
                          key: _donatedSectionKey,
                          child: Column(
                            children: [
                              _buildPetsSectionHeader(context, 'Being Donated', () {
                                final portal = context.findAncestorStateOfType<UserPortalState>();
                                portal?.navigateToTab(2); 
                              }),
                              _buildPetsHorizontalList(context, petsForDonation.take(5).toList()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  );
                }
              ),

              // Available Services Section
              servicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (PaginatedResponse<ServiceModel> response) {
                  return _buildServicesSection(context, response.data);
                },
              ),

              const SizedBox(height: 100), // Space for bottom nav
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
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search pets, services, shops...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => FilterSheet.show(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
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

  Widget _buildQuickActions(BuildContext context) {
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
            clipBehavior: Clip.none, // Allow shadows
            children: [
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add pet',
                color: AppColors.secondary,
                onTap: () {
                  final user = ProviderScope.containerOf(context).read(currentUserProvider);
                  if (user == null) {
                    _showGuestRestriction(context, 'add a pet');
                  } else {
                    PetFormSheet.show(context);
                  }
                },
              ),
              _QuickActionButton(
                icon: Icons.shopping_basket_outlined,
                label: 'Buy',
                color: Colors.blue,
                onTap: () => _scrollToSection(_soldSectionKey),
              ),
              _QuickActionButton(
                icon: Icons.pets_outlined,
                label: 'Adopt',
                color: Colors.purple,
                onTap: () => _scrollToSection(_donatedSectionKey),
              ),
              _QuickActionButton(
                icon: Icons.favorite_outline,
                label: 'Donate',
                color: Colors.pink,
                onTap: () {
                  _scrollToSection(_donatedSectionKey);
                },
              ),
              _QuickActionButton(
                icon: Icons.sell_outlined,
                label: 'Sell',
                color: Colors.green,
                onTap: () {
                  _showGuestRestriction(context, 'sell a pet');
                },
              ),
              _QuickActionButton(
                icon: Icons.calendar_today,
                label: 'Book Service',
                color: Colors.orange,
                onTap: () {
                   final user = ProviderScope.containerOf(context).read(currentUserProvider);
                   if (user == null || user.primaryRole == 'user') {
                     _showGuestRestriction(context, 'book a service');
                   } else {
                     AppointmentFormSheet.show(context);
                   }
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

  Widget _buildRecentOrdersSection(BuildContext context, List<OrderModel> orders) {
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
          itemCount: orders.take(3).length,
          itemBuilder: (context, index) {
            final order = orders[index];
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
                        Text('Order #${order.id.substring(0, 5)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${order.totalAmount} RWF', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('${order.createdAt.day}/${order.createdAt.month}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  _buildOrderStatusBadge(order.status),
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
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildShopsSection(BuildContext context, List<ShopModel> shops) {
    if (shops.isEmpty) return const SizedBox.shrink();
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
                  portal?.navigateToTab(2); // Marketplace tab
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
            clipBehavior: Clip.none, // Allow shadows
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return GestureDetector(
                onTap: () => context.push('/shop-details/${shop.id}'),
                child: Container(
                  width: 220, // Increased Width
                  margin: const EdgeInsets.symmetric(horizontal: 8), // Increased spacing
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

  Widget _buildProductsSection(BuildContext context, List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();
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
                  portal?.navigateToTab(2); // Marketplace tab
                },
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200, // Increased Height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.none, // Allow shadows
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => context.push('/product-details/${product.id}'),
                child: Container(
                  width: 200, // Increased Width
                  margin: const EdgeInsets.symmetric(horizontal: 8), // Increased spacing
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
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
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.effectivePrice.toInt()} RWF',
                              style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
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
    if (services.isEmpty) return const SizedBox.shrink();
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
                  portal?.navigateToTab(1); // Services tab
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
            clipBehavior: Clip.none,
            itemCount: services.take(5).length,
            itemBuilder: (context, index) {
              final service = services[index];
              return GestureDetector(
                onTap: () => context.push('/service-details/${service.id}'),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
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
                          color: AppColors.secondary.withValues(alpha: 0.1),
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

  Widget _buildPetsSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  Widget _buildPetsHorizontalList(BuildContext context, List<PetModel> pets) {
    return SizedBox(
      height: 200, // Increased Height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return GestureDetector(
            onTap: () => context.push('/pet-details/${pet.id}'),
            child: Container(
              width: 200, // Increased Width
              margin: const EdgeInsets.symmetric(horizontal: 8),
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
                      child: pet.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: pet.images.first,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(color: AppColors.inputFill),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          '${pet.breed?.name ?? 'Unknown'} • ${pet.ageYears} yrs',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
    );
  }

  void _showGuestRestriction(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Pet Ownership Required', textAlign: TextAlign.center),
        content: Text(
          'To perform this action, you must own a pet by either creating it, buying it, or adopting it.',
          textAlign: TextAlign.center,
        ),
        actions: [], // No buttons as requested
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _CategoriesWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final Function(String) onCategorySelected;

  const _CategoriesWidget({
    required this.categories,
    required this.selectedId,
    required this.onCategorySelected,
  });

  static const Color _catColor = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = selectedId == category.id;
          final letter = category.name.isNotEmpty
              ? category.name.substring(0, 1).toUpperCase()
              : '?';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              key: ValueKey('cat_${category.id}'),
              onTap: () => onCategorySelected(category.id),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: isActive ? _catColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _catColor, width: 1.5),
                      boxShadow: isActive 
                        ? [BoxShadow(color: _catColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                        : null,
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 24,
                          color: isActive ? Colors.white : _catColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _catColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border(left: BorderSide(color: AppColors.secondary, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: AppColors.secondary.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Column(
               children: [
                 Text('${appointment.scheduledAt.month}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                 Text('${appointment.scheduledAt.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.secondary)),
               ],
             ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.service?.name ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('At ${appointment.provider?.fullName ?? 'Provider'}', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                 Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(appointment.scheduledTime ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Triggering hot reload fix
