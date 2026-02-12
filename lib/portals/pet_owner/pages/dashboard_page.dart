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
// import '../../../core/widgets/appointment_form_sheet.dart'; // Unused in this file according to previous read, but keeping if needed
import '../../../core/widgets/all_appointments_sheet.dart';
import '../../../core/widgets/all_orders_sheet.dart';
// import '../../../core/widgets/appointment_detail_sheet.dart'; // Unused here?
import '../widgets/pet_form_sheet.dart'; 
import '../../../data/providers/species_provider.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/providers/appointment_providers.dart';
import '../../../data/providers/shop_providers.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/providers/product_providers.dart';
import '../../../data/providers/order_providers.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/services/pet_service.dart';

import '../../../data/models/models.dart';
import '../pet_owner_portal.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null;
    
    // Async Providers
    final servicesAsync = ref.watch(allServicesProvider(const ServiceQueryParams(limit: 5)));
    final appointmentsAsync = isGuest 
        ? const AsyncValue<PaginatedResponse<AppointmentModel>>.data(const PaginatedResponse(data: [], page: 1, limit: 5, total: 0, totalPages: 0))
        : ref.watch(myAppointmentsProvider(null));
    final shopsAsync = ref.watch(allShopsProvider(const ShopQueryParams(limit: 5)));
    final petsAsync = ref.watch(allPetsProvider(const PetQueryParams(limit: 10)));
    final productsAsync = ref.watch(allProductsProvider(const ProductQueryParams(limit: 10)));
    final ordersAsync = isGuest 
        ? const AsyncValue<List<OrderModel>>.data([]) 
        : ref.watch(myOrdersProvider(null));

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
                            portal?.navigateToTab(5); // Profile is usually last tab index, check UserPortal
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
              ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (List<OrderModel> orders) {
                  if (orders.isEmpty) return const SizedBox.shrink();
                  return _buildRecentOrdersSection(context, orders);
                }
              ),
              const SizedBox(height: 24),

              // Shops Section
              shopsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (PaginatedResponse<ShopModel> response) {
                  return _buildShopsSection(context, response.data);
                },
              ),
              const SizedBox(height: 24),

              // Products Section
              productsAsync.when(
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (err, stack) => const SizedBox.shrink(),
                 data: (PaginatedResponse<ProductModel> response) {
                   return _buildProductsSection(context, response.data);
                 },
              ),
              const SizedBox(height: 24),

              // Pets Section (Sale/Donation)
              petsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
                data: (PaginatedResponse<PetModel> response) {
                   final List<PetModel> browsablePets = response.data;
                   final petsForSale = browsablePets.where((p) => p.listingType == 'FOR_SALE').toList();
                   final petsForDonation = browsablePets.where((p) => p.listingType == 'FOR_DONATION').toList();
                   
                   return Column(
                     children: [
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
    final speciesAsync = ref.watch(speciesProvider);
    return speciesAsync.when(
      data: (categories) => _CategoriesWidget(categories: categories),
      loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
      error: (e, r) => const SizedBox.shrink(),
    );
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
              // _QuickActionButton(icon: Icons.compare_arrows, label: 'Mate Check', color: AppColors.success, onTap: () => _showMateCheckModal(context, ref)), // Commented out until modal logic is ported
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
        color: color.withOpacity(0.15),
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
                onTap: () => context.push('/shop-details/${shop.id}'), // Route needs to exist
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
                onTap: () => context.push('/product-details/${product.id}'), // Route needs to exist
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

  Widget _buildPetsHorizontalList(List<PetModel> pets) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return GestureDetector(
            onTap: () => context.push('/pet-details/${pet.id}'),
            child: Container(
              width: 140,
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
                    padding: const EdgeInsets.all(8),
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

  // NOTE: In a real app we would move these private widgets and modals to separate files
  // but keeping them here for now to avoid creating too many files at once.
  
  void _showAddPetModal(BuildContext context) {
    PetFormSheet.show(context);
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
                color: color.withOpacity(0.1),
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
  final List<SpeciesModel> categories;
  const _CategoriesWidget({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final gradient = _getGradient(category.name);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (category.icon != null && category.icon!.isNotEmpty)
                          ? category.icon!
                          : category.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: (category.icon != null && category.icon!.isNotEmpty) ? 28 : 24,
                        color: Colors.white,
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
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LinearGradient _getGradient(String name) {
    final int hash = name.hashCode;
    final List<List<Color>> palettes = [
      [const Color(0xFF6366F1), const Color(0xFF818CF8)], // Indigo
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)], // Amber
      [const Color(0xFF10B981), const Color(0xFF34D399)], // Emerald
      [const Color(0xFFEF4444), const Color(0xFFF87171)], // Red
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)], // Violet
      [const Color(0xFFEC4899), const Color(0xFFFB7185)], // Pink/Rose
      [const Color(0xFF06B6D4), const Color(0xFF22D3EE)], // Cyan
    ];
    
    final palette = palettes[hash.abs() % palettes.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: palette,
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
               color: AppColors.secondary.withOpacity(0.1),
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
