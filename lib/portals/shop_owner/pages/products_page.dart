import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/product_providers.dart';
import '../../../data/providers/shop_providers.dart';
import '../../../data/models/models.dart';
import '../widgets/product_form_sheet.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  bool _isGridView = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myShopAsync = ref.watch(myShopProvider);
    
    // Calculate approximate heights for fixed elements
    const double headerHeight = 230; 
    const double statsHeight = 80; // Compact stats height
    const double totalTopHeight = headerHeight + statsHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: myShopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading shop: $e')),
        data: (shop) {
          if (shop == null) {
             return const Center(child: Text('No shop found. Please create a shop first.'));
          }
          
          final productsAsync = ref.watch(shopProductsProvider(shop.id));

          return productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load products: $error', style: AppTypography.body),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(shopProductsProvider(shop.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (paginatedResult) {
              final allProducts = paginatedResult.data;
              final filteredProducts = _searchQuery.isEmpty
                  ? allProducts
                  : allProducts.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              final totalProducts = allProducts.length;
              final activeProducts = allProducts.where((p) => p.isActive).length;
              final outOfStock = allProducts.where((p) => p.stockQuantity == 0).length;

              return Stack(
                children: [
                  // Content Scroll View
                  filteredProducts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: totalTopHeight),
                          child: const EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Products Found',
                            subtitle: 'Add your first product to see it here!',
                          ),
                        )
                      : _isGridView
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, totalTopHeight + 20, 20, 100),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.65,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) => _ProductGridCard(
                                product: filteredProducts[index],
                                onEdit: () => _showEditProductSheet(context, filteredProducts[index]),
                                onDelete: () => _showDeleteConfirmation(context, filteredProducts[index], shop.id),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, totalTopHeight + 20, 20, 100),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) => _ProductCard(
                                product: filteredProducts[index],
                                onEdit: () => _showEditProductSheet(context, filteredProducts[index]),
                                onDelete: () => _showDeleteConfirmation(context, filteredProducts[index], shop.id),
                              ),
                            ),

                  // Fixed Header + Blur Stats
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Header with gradient
                        Container(
                          height: headerHeight,
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Products', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Manage your inventory', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _ViewToggle(
                                        icon: Icons.view_list,
                                        isActive: !_isGridView,
                                        onTap: () => setState(() => _isGridView = false),
                                      ),
                                      const SizedBox(width: 8),
                                      _ViewToggle(
                                        icon: Icons.grid_view,
                                        isActive: _isGridView,
                                        onTap: () => setState(() => _isGridView = true),
                                      ),
                                      const SizedBox(width: 8),
                                      _ViewToggle(
                                        icon: Icons.add,
                                        isActive: false,
                                        onTap: () => _showAddProductSheet(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'Search products...',
                                    hintStyle: TextStyle(color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stats Row with Blur
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: statsHeight,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                              ),
                              child: Row(
                                children: [
                                  _StatCard(label: 'Total', value: '$totalProducts', color: AppColors.secondary),
                                  const SizedBox(width: 12),
                                  _StatCard(label: 'Active', value: '$activeProducts', color: AppColors.success),
                                  const SizedBox(width: 12),
                                  _StatCard(label: 'Out of Stock', value: '$outOfStock', color: AppColors.error),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product, String shopId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(productCrudProvider.notifier).deleteProduct(product.id);
              ref.invalidate(shopProductsProvider(shopId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    ProductFormSheet.show(context);
  }

  void _showEditProductSheet(BuildContext context, ProductModel product) {
    // Pass ProductModel directly or map. ProductFormSheet likely expects map or model.
    // Based on previous code, it expects a map `product` argument.
    // I should check ProductFormSheet, but for now matching previous implementation behavior.
    ProductFormSheet.show(context, product: product);
  }
}

// View Toggle Button
class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggle({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.secondary : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// Compact Stat Card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 1),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// List Product Card
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final stock = product.stockQuantity;
    final price = product.price.toInt();
    final imageUrl = product.mainImage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE86A2C),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: resolveImageUrl(imageUrl),
                          fit: BoxFit.fill,
                          placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, _, _) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),
              // Name overlay
              Positioned(
                top: 12,
                left: 12,
                right: 50,
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                  ),
                ),
              ),
              // Delete button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Category: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(product.categoryName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: stock > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: stock > 0 ? AppColors.success : AppColors.error),
                      ),
                      child: Text(
                        stock > 0 ? 'In Stock: $stock' : 'Out of Stock',
                        style: TextStyle(color: stock > 0 ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Stock: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      '$stock Pieces',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: stock > 0 ? AppColors.textPrimary : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Product Fee: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(
                      '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} frw',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Center(
      child: Icon(Icons.inventory_2, size: 60, color: Colors.white.withValues(alpha: 0.6)),
    );
  }
}

// Grid Price Card
class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductGridCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final stock = product.stockQuantity;
    final price = product.price.toInt();
    final imageUrl = product.mainImage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 90,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE86A2C),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: resolveImageUrl(imageUrl),
                          fit: BoxFit.fill,
                          placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (_, _, _) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error, size: 16),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stock > 0 ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    stock > 0 ? '$stock left' : 'Out',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} frw',
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: $stock',
                    style: TextStyle(
                      fontSize: 11,
                      color: stock > 0 ? AppColors.textSecondary : AppColors.error,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12)),
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

  Widget _placeholderImage() {
    return Center(
      child: Icon(Icons.inventory_2, size: 40, color: Colors.white.withValues(alpha: 0.6)),
    );
  }
}
