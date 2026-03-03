import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/toast_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/product_providers.dart';
import '../../../data/providers/category_providers.dart';
import '../../../data/providers/shop_providers.dart';
import '../../../data/services/storage_service.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  final ProductModel? product;

  const ProductFormSheet({super.key, this.product});

  static void show(BuildContext context, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => ProductFormSheet(product: product),
      ),
    );
  }

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  late TextEditingController _skuController;
  late TextEditingController _discountController;
  String? _selectedCategory;
  XFile? _newImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isActive = true;
  bool _isFeatured = false;

  final _picker = ImagePicker();
  final _storageService = StorageService(DioClient());

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _discountController = TextEditingController(text: widget.product?.discountPercentage?.toString() ?? '');
    _selectedCategory = widget.product?.categoryId;
    _isActive = widget.product?.isActive ?? true;
    _isFeatured = widget.product?.isFeatured ?? false;
    _existingImageUrl = (widget.product?.images.isNotEmpty == true)
        ? widget.product!.images.first
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _skuController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  /// Sanitise a string for use in file/folder names.
  String _safeName(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  /// Upload the newly picked image and return its server URL.
  /// Saved at: uploads/products/<shopName>/<productName>.ext
  Future<String?> _uploadNewImage(String shopName) async {
    if (_newImage == null) return null;
    try {
      final ext = _newImage!.path.contains('.')
          ? '.${_newImage!.path.split('.').last}'
          : '.jpg';
      final folder = 'products/${_safeName(shopName)}';
      final filename = '${_safeName(_nameController.text)}$ext';
      final url = await _storageService.uploadFile(
        _newImage!.path,
        folder: folder,
        filename: filename,
      );
      return url.isNotEmpty ? url : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check shop
    final shop = ref.read(myShopProvider).value;
    if (shop == null) {
      ToastService.error(context, "Shop not loaded");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload the new image if one was picked
      final uploadedUrl = await _uploadNewImage(shop.name);
      // Use new image if uploaded, otherwise keep existing, otherwise empty
      final allImages = <String>[
        if (uploadedUrl != null) uploadedUrl
        else if (_existingImageUrl != null) _existingImageUrl!,
      ];

      final notifier = ref.read(productCrudProvider.notifier);
      final price = double.tryParse(_priceController.text) ?? 0;
      final stockQuantity = int.tryParse(_stockController.text) ?? 0;
      final discountPercentage = double.tryParse(_discountController.text);

      if (isEdit) {
        // Update
        final success = await notifier.updateProduct(widget.product!.id, {
          'name': _nameController.text,
          'price': price,
          'stockQuantity': stockQuantity,
          'description': _descController.text,
          'categoryId': _selectedCategory,
          'sku': _skuController.text.isNotEmpty ? _skuController.text : null,
          'discountPercentage': discountPercentage,
          'isActive': _isActive,
          'isFeatured': _isFeatured,
          'images': allImages,
        });
        
        if (success != null && mounted) {
          ToastService.success(context, "Product updated");
          Navigator.pop(context);
          ref.invalidate(shopProductsProvider(shop.id));
        } else if (mounted) {
          ToastService.error(context, "Failed to update product");
        }
      } else {
        // Create
        final success = await notifier.createProduct(
          shopId: shop.id,
          name: _nameController.text,
          price: price,
          stockQuantity: stockQuantity,
          description: _descController.text,
          categoryId: _selectedCategory,
          discountPercentage: discountPercentage,
          sku: _skuController.text.isNotEmpty ? _skuController.text : null,
          isActive: _isActive,
          isFeatured: _isFeatured,
          images: allImages,
        );

        if (success != null && mounted) {
          ToastService.success(context, "Product created");
          Navigator.pop(context);
          ref.invalidate(shopProductsProvider(shop.id));
        } else if (mounted) {
           ToastService.error(context, "Failed to create product");
        }
      }
    } catch (e) {
      if (mounted) ToastService.error(context, "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
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
                isEdit ? 'Edit Product' : 'Add New Product',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
  
              // ─── Image Picker (single image) ───────────────────
              const Text('Product Image', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (image != null) {
                      setState(() {
                        _newImage = image;
                        _existingImageUrl = null; // new pick replaces existing
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 100 / 255.0), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _newImage != null
                              ? Image.file(
                                  File(_newImage!.path),
                                  width: 150, height: 150,
                                  fit: BoxFit.cover,
                                )
                              : _existingImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: resolveImageUrl(_existingImageUrl!),
                                      width: 150, height: 150,
                                      fit: BoxFit.cover,
                                      placeholder: (_, _) => const Center(
                                        child: SizedBox(
                                          width: 24, height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (_, url, error) => Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, color: AppColors.secondary, size: 40),
                                          const SizedBox(height: 8),
                                          const Text('Image load failed', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, color: AppColors.secondary, size: 40),
                                        const SizedBox(height: 8),
                                        const Text('Add Photo', style: TextStyle(color: AppColors.textSecondary)),
                                      ],
                                    ),
                        ),
                      ),
                      if (_newImage != null || _existingImageUrl != null)
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _newImage = null;
                              _existingImageUrl = null;
                            }),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
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
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      child: categoriesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => const Text('Error loading categories'),
                        data: (categories) => DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          hint: const Text('Select category'),
                          items: categories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                        ),
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
                      label: 'SKU (Optional)',
                      hint: 'PROD-1234',
                      prefixIcon: Icons.qr_code,
                      controller: _skuController,
                    ),
                  ),
                  const SizedBox(width: 12),
                   Expanded(
                    child: AppTextField(
                      label: 'Discount (%)',
                      hint: '10',
                      prefixIcon: Icons.percent,
                      controller: _discountController,
                      keyboardType: TextInputType.number,
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
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
              const SizedBox(height: 16),

              // Status Toggles
              SwitchListTile(
                title: const Text('Active Product', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Show this product in your shop', style: TextStyle(fontSize: 12)),
                value: _isActive,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              SwitchListTile(
                title: const Text('Featured Product', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Highlight this on your shop frontpage', style: TextStyle(fontSize: 12)),
                value: _isFeatured,
                activeColor: AppColors.secondary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isFeatured = v),
              ),
              const SizedBox(height: 24),
  
              PrimaryButton(
                label: isEdit ? 'Save Changes' : 'Add Product',
                isLoading: _isLoading,
                onPressed: _save,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
