/// User Model matching backend User entity
class UserModel {
  final String id;
  final String? userCode;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? address;
  final List<String> roles;
  final bool isActive;
  final bool isVerified;
  final String? verificationStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    this.userCode,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.address,
    required this.roles,
    required this.isActive,
    required this.isVerified,
    this.verificationStatus,
    required this.createdAt,
    this.updatedAt,
  });

  /// Parse roles from either string array, object array, or Prisma userRoles.
  /// Login returns: roles: ['PET_OWNER']
  /// Auth profile returns: roles: [{id, name, roleType: 'PET_OWNER'}]
  /// GET /users/me returns: userRoles: [{role: {roleType: 'PET_OWNER'}}]
  static List<String> _parseRoles(dynamic rolesJson, dynamic userRolesJson) {
    // Try 'roles' first (from login / auth profile)
    if (rolesJson != null && rolesJson is List && (rolesJson as List).isNotEmpty) {
      return (rolesJson as List).map((e) {
        if (e is String) return e;
        if (e is Map) return (e['roleType'] ?? e['name'] ?? '').toString();
        return e.toString();
      }).where((r) => r.isNotEmpty).toList();
    }
    // Fallback to 'userRoles' (from raw Prisma entity via GET /users/me)
    if (userRolesJson != null && userRolesJson is List) {
      return (userRolesJson as List).map((e) {
        if (e is Map) {
          final role = e['role'];
          if (role is Map) return (role['roleType'] ?? role['name'] ?? '').toString();
          return (e['roleType'] ?? e['name'] ?? '').toString();
        }
        return e.toString();
      }).where((r) => r.isNotEmpty).toList();
    }
    return [];
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      userCode: json['userCode']?.toString(),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      bio: json['bio']?.toString(),
      address: json['address']?.toString(),
      roles: _parseRoles(json['roles'], json['userRoles']),
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationStatus: json['verificationStatus']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCode': userCode,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'address': address,
      'roles': roles,
      'isActive': isActive,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Get the primary role for portal routing
  String get primaryRole {
    if (roles.contains('ADMIN')) return 'admin';
    if (roles.contains('VETERINARY') || roles.contains('VET_DOCTOR')) return 'provider';
    if (roles.contains('PET_GROOMER') || roles.contains('PET_TRAINER') || roles.contains('PET_WALKER')) return 'provider';
    if (roles.contains('SHOP_OWNER')) return 'shop_owner';
    if (roles.contains('PET_OWNER')) return 'pet_owner';
    return 'user';
  }

  UserModel copyWith({
    String? id,
    String? userCode,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? address,
    List<String>? roles,
    bool? isActive,
    bool? isVerified,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      roles: roles ?? this.roles,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
