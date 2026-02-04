/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Rwanda Pet Lovers';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String onboardingCompleteKey = 'onboarding_complete';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 10;

  // File Upload
  static const int maxFileSizeMB = 10;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedVideoTypes = ['mp4', 'webm'];
}

/// User Roles matching backend RBAC
enum UserRole {
  user('USER'),
  petOwner('PET_OWNER'),
  shopOwner('SHOP_OWNER'),
  veterinary('VETERINARY'),
  hospitalDoctor('HOSPITAL_DOCTOR'),
  groomer('GROOMER'),
  petWalker('PET_WALKER'),
  petTrainer('PET_TRAINER'),
  admin('ADMIN');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }
}
