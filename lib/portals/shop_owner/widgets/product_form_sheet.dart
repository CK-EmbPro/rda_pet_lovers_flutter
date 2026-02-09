import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class ProductFormSheet extends StatefulWidget {
  final Map<String, dynamic>? product;
  final bool isEdit;

  const ProductFormSheet({
    super.key,
    this.product,
    this.isEdit = false,
  });

  static void show(BuildContext context, {Map<String, dynamic>? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => ProductFormSheet(
          product: product,
          isEdit: product != null,
        ),
      ),
    );
  }

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  String? _selectedCategory;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['name'] as String? ?? '');
    _priceController = TextEditingController(text: widget.product?['price']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?['stock']?.toString() ?? '');
    _descController = TextEditingController(); // Description not in mock yet
    _selectedCategory = widget.product?['category'] as String?;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isEdit ? 'Edit Product' : 'Add New Product',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Image Picker
            Center(
              child: GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _imagePath = image.path);
                  }
                },
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withAlpha(100), width: 2, style: BorderStyle.solid),
                    image: _imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : (widget.product?['image'] != null
                            ? DecorationImage(
                                image: NetworkImage(widget.product!['image'] as String),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_imagePath == null && widget.product?['image'] == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppColors.secondary, size: 40),
                            const SizedBox(height: 8),
                            const Text('Add Photo', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form fields
            AppTextField(
              label: 'Product Name',
              hint: 'e.g: Premium Dog Food',
              prefixIcon: Icons.inventory_2,
              controller: _nameController,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      hint: const Text('Select category'),
                      items: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Price (RWF)',
                    hint: '25000',
                    prefixIcon: Icons.monetization_on,
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Stock',
                    hint: '50',
                    prefixIcon: Icons.inventory,
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Description',
              hint: 'Describe your product...',
              prefixIcon: Icons.description,
              controller: _descController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: widget.isEdit ? 'Save Changes' : 'Add Product',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
