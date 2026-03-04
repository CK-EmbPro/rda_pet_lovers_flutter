import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/toast_service.dart';
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
        error: (e, _) => Center(child: Text('Something went wrong. Pull down to retry.')),
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
                                onToggleActive: () => _toggleProductActive(filteredProducts[index], shop.id),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, totalTopHeight + 20, 20, 100),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) => _ProductCard(
                                product: filteredProducts[index],
                                onEdit: () => _showEditProductSheet(context, filteredProducts[index]),
                                onDelete: () => _showDeleteConfirmation(context, filteredProducts[index], shop.id),
                                onToggleActive: () => _toggleProductActive(filteredProducts[index], shop.id),
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
                                    filled: true,
                                    fillColor: Colors.white,
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
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('Are you sure you want to delete "${product.name}"?'),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.textSecondary),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isDeleting
                          ? null
                          : () async {
                              setDialogState(() => isDeleting = true);
                              try {
                                final deleted = await ref.read(productCrudProvider.notifier).deleteProduct(product.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (deleted) {
                                  ref.invalidate(shopProductsProvider(shopId));
                                  if (mounted) ToastService.success(context, 'Product deleted');
                                } else {
                                  if (mounted) ToastService.error(context, 'Failed to delete product');
                                }
                              } catch (e) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) ToastService.error(context, 'Something went wrong. Please try again.');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isDeleting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProductSheet(BuildContext context) {
    ProductFormSheet.show(context);
  }

  void _showEditProductSheet(BuildContext context, ProductModel product) {
    ProductFormSheet.show(context, product: product);
  }

  Future<void> _toggleProductActive(ProductModel product, String shopId) async {
    final newActive = !product.isActive;
    final label = newActive ? 'activated' : 'deactivated';
    try {
      final result = await ref.read(productCrudProvider.notifier).updateProduct(
        product.id,
        {'isActive': newActive},
      );
      if (result != null) {
        ref.invalidate(shopProductsProvider(shopId));
        if (mounted) ToastService.success(context, 'Product $label');
      } else {
        if (mounted) ToastService.error(context, 'Failed to update product');
      }
    } catch (e) {
      if (mounted) ToastService.error(context, 'Something went wrong. Please try again.');
    }
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
  final VoidCallback onToggleActive;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final stock = product.stockQuantity;
    final price = product.price.toInt();
    final imageUrl = product.mainImage;

    return Opacity(
      opacity: product.isActive ? 1.0 : 0.65,
      child: Container(
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
                  height: 250,
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
                // Inactive badge
                if (!product.isActive)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'INACTIVE',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // Three-dot menu
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ProductPopupMenu(
                    product: product,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onToggleActive: onToggleActive,
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
                      Flexible(
                        child: Row(
                          children: [
                            const Text('Category: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Flexible(child: Text(product.categoryName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Center(
      child: Icon(Icons.inventory_2, size: 60, color: Colors.white.withValues(alpha: 0.6)),
    );
  }
}

// Grid Product Card
class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _ProductGridCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final stock = product.stockQuantity;
    final price = product.price.toInt();
    final imageUrl = product.mainImage;

    return Opacity(
      opacity: product.isActive ? 1.0 : 0.65,
      child: Container(
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
                  height: 120,
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
                // Three-dot menu
                Positioned(
                  top: 4,
                  right: 4,
                  child: _ProductPopupMenu(
                    product: product,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onToggleActive: onToggleActive,
                    isCompact: true,
                  ),
                ),
                // Stock badge
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
                // Inactive badge
                if (!product.isActive)
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'INACTIVE',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Center(
      child: Icon(Icons.inventory_2, size: 40, color: Colors.white.withValues(alpha: 0.6)),
    );
  }
}

/// Reusable three-dot popup menu for product cards
class _ProductPopupMenu extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final bool isCompact;

  const _ProductPopupMenu({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 16),
      ),
      child: SizedBox(
        width: isCompact ? 30 : 34,
        height: isCompact ? 30 : 34,
        child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: isCompact ? 14 : 16, color: Colors.white),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
              break;
            case 'toggle':
              onToggleActive();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20, color: AppColors.secondary),
                SizedBox(width: 10),
                Text('Edit', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: product.isActive ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 10),
                Text(
                  product.isActive ? 'Deactivate' : 'Activate',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                SizedBox(width: 10),
                Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    ),
    ),
    ),
    );
  }
}
