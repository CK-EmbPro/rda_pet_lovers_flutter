import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

final List<Map<String, dynamic>> _mockProducts = [
  {'name': 'Premium Dog Food', 'price': 25000, 'stock': 50, 'active': true},
  {'name': 'Cat Toys Bundle', 'price': 15000, 'stock': 30, 'active': true},
  {'name': 'Pet Collar Set', 'price': 8000, 'stock': 100, 'active': true},
  {'name': 'Dog Shampoo', 'price': 12000, 'stock': 0, 'active': false},
];

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          GradientHeader(
            title: 'Products',
            subtitle: 'Manage your inventory',
          ),
          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _mockProducts.length,
              itemBuilder: (context, index) {
                final product = _mockProducts[index];
                return _ProductCard(product: product);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(context),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add New Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const AppTextField(label: 'Product Name', hint: 'e.g: Premium Dog Food', prefixIcon: Icons.inventory_2),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: AppTextField(label: 'Price (RWF)', hint: '25000', prefixIcon: Icons.monetization_on)),
                SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Stock', hint: '50', prefixIcon: Icons.inventory)),
              ],
            ),
            const SizedBox(height: 16),
            const AppTextField(label: 'Description', hint: 'Describe your product...', prefixIcon: Icons.description),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Add Product', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isActive = product['active'] == true;
    final stock = product['stock'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.shopping_bag, size: 28, color: AppColors.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${product['price']} RWF', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: stock > 0 ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        stock > 0 ? 'In Stock: $stock' : 'Out of Stock',
                        style: TextStyle(color: stock > 0 ? AppColors.success : AppColors.error, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(value: isActive, onChanged: (v) {}, activeColor: AppColors.secondary),
              const Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

