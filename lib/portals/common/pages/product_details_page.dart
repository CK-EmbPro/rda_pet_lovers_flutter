import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/providers/cart_provider.dart';

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
    final products = ref.watch(productsProvider);
    final product = products.firstWhere((p) => p.id == widget.productId, orElse: () => products.first);
    final shops = ref.watch(shopsProvider);
    final shop = shops.firstWhere((s) => s.id == product.shopId, orElse: () => shops.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header Container with Image
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.4,
            pinned: true,
            backgroundColor: const Color(0xFF90C2F7), // Light blue background like in "Crocket" design
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.mainImage != null)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: CachedNetworkImage(
                        imageUrl: product.mainImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  // Decorative graphics could go here if available
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
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
                              Text(product.name, style: AppTypography.h1.copyWith(fontSize: 40)), // Bold, large title like design
                              Text(product.categoryName ?? 'Pet Food', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 18)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(shop.address?.split(',').first ?? 'Kicukiro', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
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
                    const SizedBox(height: 24),

                    // Feature Stats Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         _StatCard(label: 'Animal', value: 'Dog'), // Simplified for now
                         _StatCard(label: 'Packages', value: '${product.stockQuantity}'),
                         _StatCard(label: 'Weight', value: '50 kg'), // Mocking based on design
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Shop Section
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: shop.logoUrl != null ? CachedNetworkImageProvider(shop.logoUrl!) : null,
                          child: shop.logoUrl == null ? const Icon(Icons.store) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                              Text('Pet Retailer', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.person_outline, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Summary
                    Text('Summary', style: AppTypography.h2),
                    const SizedBox(height: 12),
                    Text(
                      product.description ?? 'These Croketsare rich in proteins and Vitamins that are efficient and ready to nuture your dog and protect your Dog from deseases.',
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Pricing
                    Row(
                      children: [
                        Text('Price (a package): ', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        Text('${product.effectivePrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}, ")} Frw', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => quantity++),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('$quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (quantity > 1) setState(() => quantity--);
                                },
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            Text('${(product.effectivePrice * quantity).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}, ")} Frw', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Action Button
                    PrimaryButton(
                      label: 'Buy Now',
                      onPressed: () {
                         ref.read(cartProvider.notifier).addProduct(product);
                         context.push('/cart');
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 80) / 3,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
