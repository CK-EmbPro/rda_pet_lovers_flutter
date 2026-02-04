/// Pet Model matching backend Pet entity
class PetModel {
  final String id;
  final String petCode;
  final String ownerId;
  final String name;
  final String speciesId;
  final String? breedId;
  final String gender;
  final double? weightKg;
  final int? ageYears;
  final DateTime? birthDate;
  final String? locationId;
  final String? nationality;
  final List<String> images;
  final List<String> videos;
  final String? description;
  final String? healthSummary;
  final Map<String, dynamic>? vaccinationStatus;
  final String donationStatus;
  final String sellingStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Nested relations
  final SpeciesModel? species;
  final BreedModel? breed;
  final UserBasicModel? owner;
  final LocationModel? location;

  PetModel({
    required this.id,
    required this.petCode,
    required this.ownerId,
    required this.name,
    required this.speciesId,
    this.breedId,
    required this.gender,
    this.weightKg,
    this.ageYears,
    this.birthDate,
    this.locationId,
    this.nationality,
    this.images = const [],
    this.videos = const [],
    this.description,
    this.healthSummary,
    this.vaccinationStatus,
    required this.donationStatus,
    required this.sellingStatus,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.species,
    this.breed,
    this.owner,
    this.location,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      petCode: json['petCode'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      speciesId: json['speciesId'] as String,
      breedId: json['breedId'] as String?,
      gender: json['gender'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      ageYears: json['ageYears'] as int?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      locationId: json['locationId'] as String?,
      nationality: json['nationality'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String?,
      healthSummary: json['healthSummary'] as String?,
      vaccinationStatus: json['vaccinationStatus'] as Map<String, dynamic>?,
      donationStatus: json['donationStatus'] as String,
      sellingStatus: json['sellingStatus'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      species: json['species'] != null
          ? SpeciesModel.fromJson(json['species'] as Map<String, dynamic>)
          : null,
      breed: json['breed'] != null
          ? BreedModel.fromJson(json['breed'] as Map<String, dynamic>)
          : null,
      owner: json['owner'] != null
          ? UserBasicModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petCode': petCode,
      'ownerId': ownerId,
      'name': name,
      'speciesId': speciesId,
      'breedId': breedId,
      'gender': gender,
      'weightKg': weightKg,
      'ageYears': ageYears,
      'birthDate': birthDate?.toIso8601String(),
      'locationId': locationId,
      'nationality': nationality,
      'images': images,
      'videos': videos,
      'description': description,
      'healthSummary': healthSummary,
      'vaccinationStatus': vaccinationStatus,
      'donationStatus': donationStatus,
      'sellingStatus': sellingStatus,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get displayImage => images.isNotEmpty ? images.first : '';
  bool get isForSale => sellingStatus == 'SELLING_PENDING';
  bool get isForDonation => donationStatus == 'DONATION_PENDING';
}

/// Species Model
class SpeciesModel {
  final String id;
  final String name;
  final String? icon;

  SpeciesModel({required this.id, required this.name, this.icon});

  factory SpeciesModel.fromJson(Map<String, dynamic> json) {
    return SpeciesModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}

/// Breed Model
class BreedModel {
  final String id;
  final String name;
  final String speciesId;

  BreedModel({required this.id, required this.name, required this.speciesId});

  factory BreedModel.fromJson(Map<String, dynamic> json) {
    return BreedModel(
      id: json['id'] as String,
      name: json['name'] as String,
      speciesId: json['speciesId'] as String,
    );
  }
}

/// Basic User Info (for nested relations)
class UserBasicModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? email;

  UserBasicModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.email,
  });

  factory UserBasicModel.fromJson(Map<String, dynamic> json) {
    return UserBasicModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Location Model
class LocationModel {
  final String id;
  final String name;
  final String? province;
  final String? district;
  final String? sector;

  LocationModel({
    required this.id,
    required this.name,
    this.province,
    this.district,
    this.sector,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      province: json['province'] as String?,
      district: json['district'] as String?,
      sector: json['sector'] as String?,
    );
  }

  String get fullAddress {
    final parts = [sector, district, province].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : name;
  }
}
