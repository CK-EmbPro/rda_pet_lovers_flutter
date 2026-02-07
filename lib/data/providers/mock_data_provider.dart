import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

/// Mock data provider for development
/// This will be replaced with actual API calls later

// ============== MOCK USER DATA ==============
final mockCurrentUser = UserModel(
  id: 'user-1',
  email: 'ellina@gmail.com',
  fullName: 'Ellina Dollez',
  phone: '+250788123456',
  avatarUrl: 'https://ui-avatars.com/api/?name=Ellina+Dollez&background=3B82F6&color=fff',
  roles: ['PET_OWNER'],
  isActive: true,
  isVerified: true,
  createdAt: DateTime.now().subtract(const Duration(days: 30)),
);

// ============== MOCK SPECIES & BREEDS ==============
final mockSpecies = [
  SpeciesModel(id: 'species-1', name: 'Dog', icon: '🐕'),
  SpeciesModel(id: 'species-2', name: 'Cat', icon: '🐈'),
  SpeciesModel(id: 'species-3', name: 'Bird', icon: '🐦'),
  SpeciesModel(id: 'species-4', name: 'Rabbit', icon: '🐰'),
];

final mockBreeds = [
  BreedModel(id: 'breed-1', name: 'Golden Retriever', speciesId: 'species-1'),
  BreedModel(id: 'breed-2', name: 'German Shepherd', speciesId: 'species-1'),
  BreedModel(id: 'breed-3', name: 'Labrador', speciesId: 'species-1'),
  BreedModel(id: 'breed-4', name: 'Persian', speciesId: 'species-2'),
  BreedModel(id: 'breed-5', name: 'Siamese', speciesId: 'species-2'),
  BreedModel(id: 'breed-6', name: 'Red Nepal Cat', speciesId: 'species-2'),
];

// ============== MOCK LOCATIONS ==============
final mockLocations = [
  LocationModel(id: 'loc-1', name: 'Kicukiro', province: 'Kigali', district: 'Kicukiro', sector: 'Sonatube'),
  LocationModel(id: 'loc-2', name: 'Nyarugenge', province: 'Kigali', district: 'Nyarugenge', sector: 'Muhima'),
  LocationModel(id: 'loc-3', name: 'Gasabo', province: 'Kigali', district: 'Gasabo', sector: 'Remera'),
];

// ============== MOCK PETS ==============
final mockPets = [
  PetModel(
    id: 'pet-1',
    petCode: 'PET-001',
    ownerId: 'user-1',
    name: 'Das',
    speciesId: 'species-1',
    breedId: 'breed-1',
    gender: 'MALE',
    weightKg: 45.0,
    ageYears: 1,
    birthDate: DateTime.now().subtract(const Duration(days: 365)),
    locationId: 'loc-1',
    images: [
      'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400',
      'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400',
    ],
    description: 'Das is a magnificent 1-year-old Labrador mix with a heart as warm as his golden coat. He is the perfect blend of playful energy and cozy calm.',
    healthSummary: 'Tas is now with leg injury but he is in his recovery days.',
    vaccinationStatus: {'isVaccinated': true, 'lastVaccination': '2025-01-15'},
    donationStatus: 'NOT_FOR_DONATION',
    sellingStatus: 'NOT_FOR_SALE',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 100)),
    species: mockSpecies[0],
    breed: mockBreeds[0],
    location: mockLocations[0],
  ),
  PetModel(
    id: 'pet-2',
    petCode: 'PET-002',
    ownerId: 'user-1',
    name: 'Pitou',
    speciesId: 'species-1',
    breedId: 'breed-1',
    gender: 'MALE',
    weightKg: 35.0,
    ageYears: 0,
    birthDate: DateTime.now().subtract(const Duration(days: 90)),
    images: [
      'https://images.unsplash.com/photo-1561037404-61cd46aa615b?w=400',
    ],
    description: 'A playful 3-month old puppy full of energy.',
    donationStatus: 'NOT_FOR_DONATION',
    sellingStatus: 'SELLING_PENDING',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 50)),
    species: mockSpecies[0],
    breed: mockBreeds[0],
  ),
  PetModel(
    id: 'pet-3',
    petCode: 'PET-003',
    ownerId: 'user-2',
    name: 'Tessy',
    speciesId: 'species-1',
    breedId: 'breed-2',
    gender: 'MALE',
    weightKg: 30.0,
    ageYears: 0,
    birthDate: DateTime.now().subtract(const Duration(days: 90)),
    images: [
      'https://images.unsplash.com/photo-1558788353-f76d92427f16?w=400',
    ],
    description: 'Friendly German Shepherd puppy.',
    donationStatus: 'NOT_FOR_DONATION',
    sellingStatus: 'NOT_FOR_SALE',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    species: mockSpecies[0],
    breed: mockBreeds[1],
  ),
  PetModel(
    id: 'pet-4',
    petCode: 'PET-004',
    ownerId: 'user-3',
    name: 'Minion',
    speciesId: 'species-2',
    breedId: 'breed-6',
    gender: 'FEMALE',
    weightKg: 4.5,
    ageYears: 2,
    images: [
      'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400',
    ],
    description: 'Elegant Siamese cat.',
    donationStatus: 'NOT_FOR_DONATION',
    sellingStatus: 'NOT_FOR_SALE',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 200)),
    species: mockSpecies[1],
    breed: mockBreeds[5],
  ),
  PetModel(
    id: 'pet-5',
    petCode: 'PET-005',
    ownerId: 'user-2',
    name: 'Keza',
    speciesId: 'species-1',
    breedId: 'breed-2',
    gender: 'FEMALE',
    weightKg: 25.4,
    ageYears: 1,
    images: [
      'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=400',
    ],
    description: 'Energetic and friendly.',
    donationStatus: 'NOT_FOR_DONATION',
    sellingStatus: 'FOR_SALE',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    species: mockSpecies[0],
    breed: mockBreeds[1],
  ),
];

// ============== MOCK PROVIDERS ==============
final mockProviders = [
  ProviderInfo(
    id: 'prov-1',
    fullName: 'Dr. Telesifori',
    avatarUrl: 'https://ui-avatars.com/api/?name=Dr+Telesifori&background=3B82F6&color=fff',
    phone: '+250788111111',
    specialty: 'Dog doctor specialist',
    businessName: null,
    workingHours: '8:00 am - 6:00 pm',
    isAvailable: true,
  ),
  ProviderInfo(
    id: 'prov-2',
    fullName: 'Mutabazi',
    avatarUrl: 'https://ui-avatars.com/api/?name=Mutabazi&background=3B82F6&color=fff',
    phone: '+250788222222',
    specialty: 'Veterinary specialist',
    businessName: null,
    workingHours: '8:00 am - 6:00 pm',
    isAvailable: true,
  ),
  ProviderInfo(
    id: 'prov-3',
    fullName: 'Jackson K.',
    avatarUrl: 'https://ui-avatars.com/api/?name=Jackson+K&background=3B82F6&color=fff',
    phone: '+250788333333',
    specialty: 'Trainer',
    businessName: 'Kigali Pet Trainers',
    workingHours: '8:00 am - 6:00 pm',
    isAvailable: true,
  ),
  ProviderInfo(
    id: 'prov-4',
    fullName: 'Christopher K',
    avatarUrl: 'https://ui-avatars.com/api/?name=Christopher+K&background=3B82F6&color=fff',
    phone: '+250788444444',
    specialty: 'Pet Groomer',
    businessName: 'Kicukiro Pet Care',
    workingHours: '9:00 am - 5:00 pm',
    isAvailable: true,
  ),
];

// ============== MOCK SERVICES ==============
final mockServices = [
  ServiceModel(
    id: 'svc-1',
    providerId: 'prov-1',
    serviceType: 'VETERINARY',
    name: 'General Checkup',
    description: 'Complete health examination for your pet',
    fee: 25000,
    paymentMethod: 'PAY_BEFORE',
    createdAt: DateTime.now(),
    provider: mockProviders[0],
  ),
  ServiceModel(
    id: 'svc-2',
    providerId: 'prov-2',
    serviceType: 'VETERINARY',
    name: 'Vaccination',
    description: 'Complete vaccination package',
    fee: 35000,
    paymentMethod: 'PAY_BEFORE',
    createdAt: DateTime.now(),
    provider: mockProviders[1],
  ),
  ServiceModel(
    id: 'svc-3',
    providerId: 'prov-3',
    serviceType: 'TRAINING',
    name: 'Behaviour Coach',
    description: 'Professional pet behavior training',
    fee: 50000,
    paymentMethod: 'PAY_BEFORE',
    createdAt: DateTime.now(),
    provider: mockProviders[2],
  ),
  ServiceModel(
    id: 'svc-4',
    providerId: 'prov-3',
    serviceType: 'WALKING',
    name: '10 min walk',
    description: 'Short walk for your pet',
    fee: 5000,
    paymentMethod: 'PAY_BEFORE',
    createdAt: DateTime.now(),
    provider: mockProviders[2],
  ),
  ServiceModel(
    id: 'svc-5',
    providerId: 'prov-4',
    serviceType: 'GROOMING',
    name: 'Full Grooming',
    description: 'Complete grooming package',
    fee: 30000,
    paymentMethod: 'PAY_AFTER',
    createdAt: DateTime.now(),
    provider: mockProviders[3],
  ),
];

// ============== MOCK SHOPS ==============
final mockShops = [
  ShopModel(
    id: 'shop-1',
    ownerId: 'user-shop-1',
    name: 'Pawfect Bites',
    description: 'Quality pet food and accessories',
    logoUrl: 'https://ui-avatars.com/api/?name=Pawfect+Bites&background=F59E0B&color=fff',
    address: 'Kigali, Rwanda',
    phone: '+250788555555',
    isActive: true,
    isVerified: true,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
    productCount: 25,
    rating: 4.8,
  ),
  ShopModel(
    id: 'shop-2',
    ownerId: 'user-shop-2',
    name: 'Pet Paradise',
    description: 'Everything for your furry friends',
    logoUrl: 'https://ui-avatars.com/api/?name=Pet+Paradise&background=3B82F6&color=fff',
    address: 'Kicukiro, Kigali',
    phone: '+250788666666',
    isActive: true,
    isVerified: true,
    createdAt: DateTime.now().subtract(const Duration(days: 200)),
    productCount: 40,
    rating: 4.5,
  ),
];

// ============== MOCK PRODUCTS ==============
final mockProducts = [
  ProductModel(
    id: 'prod-1',
    productCode: 'PROD-001',
    name: 'Crockets Dog Food',
    description: 'Premium dog food for healthy pets',
    price: 50000,
    discountPrice: 30000,
    stockQuantity: 5,
    mainImage: 'https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=400',
    images: ['https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=400'],
    shopId: 'shop-1',
    createdAt: DateTime.now(),
    shopName: 'Pawfect Bites',
    categoryName: 'Dog Food',
  ),
  ProductModel(
    id: 'prod-2',
    productCode: 'PROD-002',
    name: 'Cat Treats',
    description: 'Delicious treats for cats',
    price: 15000,
    stockQuantity: 20,
    mainImage: 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400',
    images: ['https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=400'],
    shopId: 'shop-1',
    createdAt: DateTime.now(),
    shopName: 'Pawfect Bites',
    categoryName: 'Cat Food',
  ),
  ProductModel(
    id: 'prod-3',
    productCode: 'PROD-003',
    name: 'Pet Toy Ball',
    description: 'Durable toy ball for dogs',
    price: 8000,
    stockQuantity: 15,
    mainImage: 'https://images.unsplash.com/photo-1535294435445-d7249524ef2e?w=400',
    images: ['https://images.unsplash.com/photo-1535294435445-d7249524ef2e?w=400'],
    shopId: 'shop-2',
    createdAt: DateTime.now(),
    shopName: 'Pet Paradise',
    categoryName: 'Toys',
  ),
  ProductModel(
    id: 'prod-4',
    productCode: 'PROD-004',
    name: 'Dog Leash',
    description: 'Strong leather leash.',
    price: 12000,
    stockQuantity: 10,
    mainImage: 'https://images.unsplash.com/photo-1601758124510-52d02ddb7cbd?w=400',
    images: ['https://images.unsplash.com/photo-1601758124510-52d02ddb7cbd?w=400'],
    shopId: 'shop-1',
    createdAt: DateTime.now(),
    shopName: 'Pawfect Bites',
    categoryName: 'Accessories',
  ),
];

// ============== MOCK CATEGORIES ==============
final mockCategories = [
  CategoryModel(id: 'cat-1', name: 'Dogs', icon: '🐕'),
  CategoryModel(id: 'cat-2', name: 'Cats', icon: '🐈'),
  CategoryModel(id: 'cat-3', name: 'Food', icon: '🍖'),
  CategoryModel(id: 'cat-4', name: 'Toys', icon: '🎾'),
  CategoryModel(id: 'cat-5', name: 'Accessories', icon: '🎀'),
];

// ============== MOCK APPOINTMENTS ==============
final mockAppointments = [
  AppointmentModel(
    id: 'apt-1',
    userId: 'user-1',
    providerId: 'prov-4',
    serviceId: 'svc-5',
    petId: 'pet-1',
    scheduledAt: DateTime(2025, 8, 28, 18, 0),
    durationMinutes: 50,
    status: 'CONFIRMED',
    totalAmount: 30000,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    provider: ProviderBasicInfo(
      id: 'prov-4',
      fullName: 'Christopher K',
      avatarUrl: 'https://ui-avatars.com/api/?name=Christopher+K&background=3B82F6&color=fff',
      businessName: 'Kicukiro Pet Care',
    ),
    pet: PetBasicInfo(
      id: 'pet-1',
      petCode: 'PET-001',
      name: 'Das',
      breed: 'Golden Retriever',
      imageUrl: 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400',
    ),
  ),
  AppointmentModel(
    id: 'apt-2',
    userId: 'user-1',
    providerId: 'prov-1',
    serviceId: 'svc-1',
    petId: 'pet-2',
    scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 9)),
    durationMinutes: 30,
    status: 'PENDING',
    totalAmount: 25000,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    provider: ProviderBasicInfo(
      id: 'prov-1',
      fullName: 'Dr. Telesifori',
      avatarUrl: 'https://ui-avatars.com/api/?name=Dr+Telesifori&background=3B82F6&color=fff',
    ),
    pet: PetBasicInfo(
      id: 'pet-2',
      petCode: 'PET-002',
      name: 'Pitou',
      breed: 'Golden Retriever',
    ),
  ),
];

// ============== RIVERPOD PROVIDERS ==============

/// Current user provider
final currentUserProvider = StateProvider<UserModel?>((ref) => mockCurrentUser);

/// Auth state
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// User role provider
final userRoleProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.primaryRole ?? 'user';
});

/// Species list provider
final speciesProvider = Provider<List<SpeciesModel>>((ref) => mockSpecies);

/// Breeds list provider
final breedsProvider = Provider<List<BreedModel>>((ref) => mockBreeds);

/// Locations provider
final locationsProvider = Provider<List<LocationModel>>((ref) => mockLocations);

/// All pets provider
final allPetsProvider = StateProvider<List<PetModel>>((ref) => mockPets);

/// Current user's pets
final myPetsProvider = Provider<List<PetModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final allPets = ref.watch(allPetsProvider);
  if (user == null) return [];
  return allPets.where((pet) => pet.ownerId == user.id).toList();
});

/// Alias for myPetsProvider to match UI naming
final userPetsProvider = myPetsProvider;

/// Pets for sale/browsing
final browsablePetsProvider = Provider<List<PetModel>>((ref) {
  final allPets = ref.watch(allPetsProvider);
  return allPets.where((pet) => pet.isActive).toList();
});

/// Providers list
final serviceProvidersProvider = Provider<List<ProviderInfo>>((ref) => mockProviders);

/// Services list
final servicesProvider = StateProvider<List<ServiceModel>>((ref) => mockServices);

/// Services by type
final servicesByTypeProvider = Provider.family<List<ServiceModel>, String?>((ref, type) {
  final services = ref.watch(servicesProvider);
  if (type == null || type == 'All') return services;
  return services.where((s) => s.serviceType == type).toList();
});

/// Shops list
final shopsProvider = Provider<List<ShopModel>>((ref) => mockShops);

/// Products list
final productsProvider = StateProvider<List<ProductModel>>((ref) => mockProducts);

/// Categories list
final categoriesProvider = Provider<List<CategoryModel>>((ref) => mockCategories);


// ============== APPOINTMENTS PROVIDER ==============

/// Appointments provider
final appointmentsProvider = StateProvider<List<AppointmentModel>>((ref) => mockAppointments);

/// My appointments (as pet owner)
final myAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final all = ref.watch(appointmentsProvider);
  if (user == null) return [];
  return all.where((apt) => apt.userId == user.id).toList();
});

/// Provider's appointments
final providerAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final all = ref.watch(appointmentsProvider);
  if (user == null) return [];
  return all.where((apt) => apt.providerId == user.id).toList();
});
