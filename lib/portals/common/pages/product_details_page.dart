import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
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
    final cart = ref.watch(cartProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong. Pull down to retry.')),
        data: (product) {
          final shopAsync = ref.watch(shopDetailProvider(product.shopId));
          final isInCart = cart.any((i) => i.id == product.id && i.type == 'PRODUCT');
          final isOutOfStock = product.stockQuantity <= 0;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Image Header - matches pet details style
                    SliverAppBar(
                      expandedHeight: 400,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
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
                            icon: Icon(
                              isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                              color: isInCart ? AppColors.secondary : Colors.black,
                              size: 20,
                            ),
                            onPressed: () {
                              final portalRoute = AppRouter.getPortalRoute(user?.primaryRole ?? 'user');
                              context.go('$portalRoute?tab=cart');
                            },
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildProductImage(product.mainImage),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        transform: Matrix4.translationValues(0, -24, 0),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Name, Price, Status
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
                                      Row(
                                        children: [
                                          const Icon(Icons.category_outlined, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              product.categoryName ?? 'Pet Product',
                                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${product.effectivePrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} RWF',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOutOfStock ? Colors.red.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isOutOfStock ? 'Out of Stock' : 'In Stock',
                                        style: TextStyle(
                                          color: isOutOfStock ? Colors.red : AppColors.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Stats Grid - matches pet details
                            Row(
                              children: [
                                Expanded(child: _buildStatCard('Stock', '${product.stockQuantity}', Icons.inventory_2)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard('Category', product.categoryName ?? 'N/A', Icons.pets)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: shopAsync.when(
                                    loading: () => _buildStatCard('Location', '...', Icons.location_on),
                                    error: (_, _) => _buildStatCard('Location', 'N/A', Icons.location_on),
                                    data: (shop) => _buildStatCard('Location', shop.address?.split(',').first ?? 'Kigali', Icons.location_on),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // About Section - same style as shop card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 12),
                                  Text(
                                    product.description ?? 'No description available for this product.',
                                    style: const TextStyle(color: Color(0xFF475569), height: 1.6, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Shop / Seller Info - matches owner card in pet details
                            shopAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (shop) => Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                      radius: 24,
                                      backgroundImage: shop.logoUrl != null ? CachedNetworkImageProvider(resolveImageUrl(shop.logoUrl!)) : null,
                                      child: shop.logoUrl == null ? const Icon(Icons.store, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            shop.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                          ),
                                          Text(
                                            shop.description?.split('.').first ?? 'Pet Shop',
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Action Bar - matches pet details
              if (!isOutOfStock)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quantity & Total row
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
                                  icon: const Icon(Icons.remove, color: Color(0xFF64748B), size: 20),
                                  onPressed: () {
                                    if (quantity > 1) setState(() => quantity--);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Color(0xFF64748B), size: 20),
                                  onPressed: () {
                                    if (quantity < product.stockQuantity) setState(() => quantity++);
                                  },
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                '${(product.effectivePrice * quantity).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} RWF',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Action buttons - matches pet details "Add to Cart" + "Buy Now"
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isInCart
                                  ? () => ref.read(cartProvider.notifier).removeItem(product.id, 'PRODUCT')
                                  : () => ref.read(cartProvider.notifier).addProduct(product),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: isInCart ? Colors.red : const Color(0xFF21314C)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                isInCart ? 'Remove' : 'Add to Cart',
                                style: TextStyle(
                                  color: isInCart ? Colors.red : const Color(0xFF21314C),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (!isInCart) {
                                  ref.read(cartProvider.notifier).addProduct(product);
                                }
                                final portalRoute = AppRouter.getPortalRoute(user?.primaryRole ?? 'user');
                                context.go('$portalRoute?tab=cart');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF21314C),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: resolveImageUrl(imageUrl),
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: Colors.grey[200]),
            errorWidget: (_, _, _) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.inventory_2, size: 64, color: Colors.grey)),
            ),
          )
        else
          Container(
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.inventory_2, size: 64, color: Colors.grey)),
          ),
        // Gradient Overlay - matches pet details
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.1),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
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
