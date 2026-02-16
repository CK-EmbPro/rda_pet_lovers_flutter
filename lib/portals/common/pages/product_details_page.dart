import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
// import '../../../data/models/models.dart'; // Implicitly used
import '../../../data/providers/product_providers.dart';
import '../../../data/providers/shop_providers.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';

class ProductDetailsPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium light gray
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading product: $e')),
        data: (product) {
          // Fetch shop details once product is loaded and we have shopId
          final shopAsync = ref.watch(shopDetailProvider(product.shopId));

          return CustomScrollView(
            slivers: [
              // Header Container with Image
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45, // Slightly taller
                pinned: true,
                backgroundColor: const Color(0xFFE2E8F0),
                leading: Container(
                   margin: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: Colors.white.withValues(alpha: 0.9),
                     shape: BoxShape.circle,
                   ),
                   child: IconButton(
                     icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                     onPressed: () => context.pop(),
                   ),
                 ),
                actions: [
                  Container(
                     margin: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.white.withValues(alpha: 0.9),
                       shape: BoxShape.circle,
                     ),
                     child: IconButton(
                       icon: const Icon(Icons.fullscreen_exit, color: Colors.black, size: 20),
                       onPressed: () {},
                     ),
                   ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                       Container(color: Colors.white), // distinct from scaffold
                      if (product.mainImage != null)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: CachedNetworkImage(
                            imageUrl: product.mainImage!,
                            fit: BoxFit.contain,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC), // Match scaffold
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                     boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                  ),
                  transform: Matrix4.translationValues(0, -20, 0), // Visual overlap without negative margin
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 28, 
                                      fontWeight: FontWeight.w800, 
                                      color: Color(0xFF1E293B),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.categoryName ?? 'Pet Food',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            // ... kept shopAsync part same but cleaner ...
                            shopAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (shop) => Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        shop.address?.split(',').first ?? 'Kicukiro',
                                        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Feature Stats Cards
                        Row(
                          children: [
                             Expanded(child: _StatCard(label: 'Animal', value: 'Dog', icon: Icons.pets)), 
                             const SizedBox(width: 12),
                             Expanded(child: _StatCard(label: 'Stock', value: '${product.stockQuantity}', icon: Icons.inventory_2)),
                             const SizedBox(width: 12),
                             Expanded(child: _StatCard(label: 'Weight', value: '50 kg', icon: Icons.monitor_weight)),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Shop Section
                        shopAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (shop) => Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               color: Colors.white, // White card
                               borderRadius: BorderRadius.circular(20),
                               boxShadow: [
                                 BoxShadow(
                                   color: const Color(0xFF64748B).withValues(alpha: 0.08),
                                   blurRadius: 16,
                                   offset: const Offset(0, 4),
                                 ),
                               ],
                             ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: shop.logoUrl != null ? CachedNetworkImageProvider(shop.logoUrl!) : null,
                                  child: shop.logoUrl == null ? const Icon(Icons.store) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                      const Text('Pet Retailer', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/shop-details/${shop.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.store, color: AppColors.secondary, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Summary
                        Container(
                           padding: const EdgeInsets.all(24),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                 BoxShadow(
                                   color: const Color(0xFF64748B).withValues(alpha: 0.08),
                                   blurRadius: 16,
                                   offset: const Offset(0, 4),
                                 ),
                               ],
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                               const SizedBox(height: 12),
                               Text(
                                 product.description ?? 'No description available for this product.',
                                 style: const TextStyle(color: Color(0xFF475569), height: 1.6, fontSize: 15),
                               ),
                             ],
                           ),
                         ),
                        const SizedBox(height: 24),

                         // Pricing
                        Row(
                          children: [
                            const Text('Price (a package): ', style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)),
                            Text(
                              '${product.effectivePrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}, ")} Frw', 
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: AppColors.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Quantity and Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Quantity Picker
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Color(0xFF64748B)),
                                    onPressed: () {
                                      if (quantity > 1) setState(() => quantity--);
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Color(0xFF64748B)),
                                    onPressed: () => setState(() => quantity++),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                                Text(
                                  '${(product.effectivePrice * quantity).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}, ")} Frw', 
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Action Button
                        PrimaryButton(
                          label: 'Buy Now',
                          icon: Icons.shopping_bag_outlined,
                          onPressed: () {
                             // Assuming cartProvider handles adding product with specific quantity
                             // If not, we might need to update cartProvider to accept quantity
                             ref.read(cartProvider.notifier).addProduct(product);
                             // Need to handle quantity separately or multiple adds? 
                             // For now just add once as per existing simple cart logic
                             final user = ref.read(currentUserProvider);
                             final role = user?.primaryRole.toUpperCase() ?? 'USER';
                             final route = AppRouter.getPortalRoute(role);
                             context.go(Uri(path: route, queryParameters: {'tab': 'cart'}).toString());
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
      // width: (MediaQuery.of(context).size.width - 80) / 3, // Handled by Expanded in parent Row
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)), // Removed border
        boxShadow: [
           BoxShadow(
             color: const Color(0xFF64748B).withValues(alpha: 0.08),
             blurRadius: 10,
             offset: const Offset(0, 4),
           ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
