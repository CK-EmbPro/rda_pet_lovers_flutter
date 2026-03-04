/// Shop Model matching backend Shop entity
class ShopModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;

  // Stats
  final int productCount;
  final double? rating;

  ShopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.phone,
    this.email,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.productCount = 0,
    this.rating,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      productCount: json['_count']?['products'] as int? ?? 0,
      rating: _parseDouble(json['rating']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Category Model for products
class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? description;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Cart Item Model
class CartItemModel {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double price;
  final int quantity;
  final String shopId;
  final String? shopName;

  CartItemModel({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.shopId,
    this.shopName,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Handle nested product object if present
    final product = json['product'] as Map<String, dynamic>?;
    return CartItemModel(
      productId: json['productId'] as String? ?? product?['id'] as String? ?? '',
      productName: json['productName'] as String? ?? product?['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? (product?['images'] is List && (product!['images'] as List).isNotEmpty ? (product['images'] as List).first as String : null),
      price: ShopModel._parseDouble(json['price']) ?? ShopModel._parseDouble(product?['price']) ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      shopId: json['shopId'] as String? ?? product?['shopId'] as String? ?? '',
      shopName: json['shopName'] as String?,
    );
  }

  double get totalPrice => price * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity ?? this.quantity,
      shopId: shopId,
      shopName: shopName,
    );
  }
}

/// Order Model
class OrderModel {
  final String id;
  final String orderCode;
  final String buyerId;
  final String? sellerId;
  final String? shopId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double? discount;
  final double totalAmount;
  final String currency;
  final String status; // PENDING, CONFIRMED, PROCESSING, COMPLETED, CANCELLED
  final String? paymentId;
  final bool isPetOrder;
  final bool isProductOrder;
  final String? notes;
  final String? cancellationReason;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.buyerId,
    this.sellerId,
    this.shopId,
    required this.items,
    required this.subtotal,
    this.discount,
    required this.totalAmount,
    this.currency = 'RWF',
    required this.status,
    this.paymentId,
    this.isPetOrder = false,
    this.isProductOrder = true,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      buyerId: (json['buyerId'] ?? json['userId'] ?? '') as String,
      sellerId: json['sellerId'] as String?,
      shopId: json['shopId'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: ShopModel._parseDouble(json['subtotal']) ?? 0,
      discount: ShopModel._parseDouble(json['discountAmount'] ?? json['discount']),
      totalAmount: ShopModel._parseDouble(json['totalAmount']) ?? 0,
      currency: json['currency'] as String? ?? 'RWF',
      status: json['status'] as String? ?? 'PENDING',
      paymentId: json['paymentId'] as String?,
      isPetOrder: json['isPetOrder'] as bool? ?? false,
      isProductOrder: json['isProductOrder'] as bool? ?? true,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get displayStatus {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PROCESSING':
        return 'Processing';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Order Item Model
class OrderItemModel {
  final String? productId;
  final String? petListingId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? imageUrl;

  OrderItemModel({
    this.productId,
    this.petListingId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl,
  });

  /// Unique key for grouping — uses productId or petListingId
  String get itemKey => productId ?? petListingId ?? productName;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Determine name and image from either product or petListing
    String name = 'Unknown Product';
    String? image;

    if (json['product'] != null) {
      name = json['product']['name'] as String? ?? 'Unknown Product';
      final images = json['product']['images'];
      if (images is List && images.isNotEmpty) {
        image = images.first as String;
      }
    } else if (json['petListing'] != null) {
      final pet = json['petListing']['pet'];
      name = pet?['name'] as String? ?? 'Pet Listing';
      final petImages = pet?['images'];
      if (petImages is List && petImages.isNotEmpty) {
        image = petImages.first as String;
      }
    }

    return OrderItemModel(
      productId: json['productId'] as String?,
      petListingId: json['petListingId'] as String?,
      productName: name,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: ShopModel._parseDouble(json['unitPrice']) ?? 0,
      totalPrice: ShopModel._parseDouble(json['totalPrice']) ?? 0,
      imageUrl: image,
    );
  }
}
