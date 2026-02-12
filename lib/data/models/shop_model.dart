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
  final String userId;
  final String shopId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double? discount;
  final double totalAmount;
  final String status; // PENDING, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
  final String? paymentStatus;
  final String? shippingAddress;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.shopId,
    required this.items,
    required this.subtotal,
    this.discount,
    required this.totalAmount,
    required this.status,
    this.paymentStatus,
    this.shippingAddress,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderCode: json['orderCode'] as String,
      userId: json['userId'] as String,
      shopId: json['shopId'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: ShopModel._parseDouble(json['subtotal']) ?? 0,
      discount: ShopModel._parseDouble(json['discount']),
      totalAmount: ShopModel._parseDouble(json['totalAmount']) ?? 0,
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String?,
      shippingAddress: json['shippingAddress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      case 'SHIPPED':
        return 'Shipped';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Order Item Model
class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? imageUrl;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as String,
      productName: json['product']?['name'] as String? ?? 'Unknown Product',
      quantity: json['quantity'] as int,
      unitPrice: ShopModel._parseDouble(json['unitPrice']) ?? 0,
      totalPrice: ShopModel._parseDouble(json['totalPrice']) ?? 0,
      imageUrl: (json['product']?['images'] is List && (json['product']['images'] as List).isNotEmpty) 
          ? (json['product']['images'] as List).first as String 
          : null,
    );
  }
}
