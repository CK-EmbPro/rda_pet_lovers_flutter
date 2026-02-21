/// Product model matching backend Product entity
class ProductModel {
  final String id;
  final String productCode;
  final String name;
  final String? description;
  final double price;
  final double? discountPercentage;
  final int stockQuantity;
  final String? sku;
  final bool isActive;
  final bool isFeatured;
  final String? mainImage;
  final List<String> images;
  final String shopId;
  final String? categoryId;
  final DateTime createdAt;

  // Nested data
  final String? shopName;
  final String? categoryName;

  ProductModel({
    required this.id,
    required this.productCode,
    required this.name,
    this.description,
    required this.price,
    this.discountPercentage,
    this.stockQuantity = 0,
    this.sku,
    this.isActive = true,
    this.isFeatured = false,
    this.mainImage,
    this.images = const [],
    required this.shopId,
    this.categoryId,
    required this.createdAt,
    this.shopName,
    this.categoryName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      productCode: json['productCode'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: _parseDouble(json['price']) ?? 0,
      discountPercentage: _parseDouble(json['discountPercentage']),
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      sku: json['sku'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      mainImage: json['mainImage'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      shopId: json['shopId'] as String,
      categoryId: json['categoryId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      shopName: json['shop']?['name'] as String?,
      categoryName: json['category']?['name'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Get the effective price (discounted or regular)
  double get effectivePrice {
    if (discountPercentage != null && discountPercentage! > 0) {
      return price - (price * (discountPercentage! / 100));
    }
    return price;
  }

  /// Check if product is on sale
  bool get isOnSale => discountPercentage != null && discountPercentage! > 0;

  /// Check if product is in stock
  bool get inStock => stockQuantity > 0;
}
