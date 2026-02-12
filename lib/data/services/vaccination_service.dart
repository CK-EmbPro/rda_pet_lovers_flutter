import '../../core/api/dio_client.dart';
import 'base_api_service.dart';

/// Vaccination Model
class VaccinationModel {
  final String id;
  final String name;
  final String? description;
  final String? manufacturer;
  final int? doseIntervalDays;
  final bool isActive;

  VaccinationModel({
    required this.id,
    required this.name,
    this.description,
    this.manufacturer,
    this.doseIntervalDays,
    this.isActive = true,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      manufacturer: json['manufacturer'] as String?,
      doseIntervalDays: json['doseIntervalDays'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Pet Vaccination Record (a vaccination administered to a specific pet)
class PetVaccinationModel {
  final String id;
  final String petId;
  final String vaccinationId;
  final DateTime administeredAt;
  final String? administeredBy;
  final DateTime? nextDueDate;
  final String? batchNumber;
  final String? notes;
  final VaccinationModel? vaccination;

  PetVaccinationModel({
    required this.id,
    required this.petId,
    required this.vaccinationId,
    required this.administeredAt,
    this.administeredBy,
    this.nextDueDate,
    this.batchNumber,
    this.notes,
    this.vaccination,
  });

  factory PetVaccinationModel.fromJson(Map<String, dynamic> json) {
    return PetVaccinationModel(
      id: json['id'] as String,
      petId: json['petId'] as String,
      vaccinationId: json['vaccinationId'] as String,
      administeredAt: DateTime.parse(json['administeredAt'] as String),
      administeredBy: json['administeredBy'] as String?,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'] as String)
          : null,
      batchNumber: json['batchNumber'] as String?,
      notes: json['notes'] as String?,
      vaccination: json['vaccination'] != null
          ? VaccinationModel.fromJson(
              json['vaccination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Vaccination API Service — handles vaccination records.
/// Protected: all endpoints require authentication.
class VaccinationService extends BaseApiService {
  VaccinationService(super.client);

  /// Get all vaccinations (catalog)
  Future<List<VaccinationModel>> getAll() async {
    return safeApiCall(() async {
      final response = await dio.get(ApiEndpoints.vaccinations);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data
          .map((json) =>
              VaccinationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Create a new vaccination type (admin)
  Future<VaccinationModel> create({
    required String name,
    String? description,
    String? manufacturer,
    int? doseIntervalDays,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        ApiEndpoints.vaccinations,
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (manufacturer != null) 'manufacturer': manufacturer,
          if (doseIntervalDays != null) 'doseIntervalDays': doseIntervalDays,
        },
      );
      return VaccinationModel.fromJson(response.data);
    });
  }

  /// Administer vaccination to a pet
  Future<PetVaccinationModel> administer({
    required String vaccinationId,
    required String petId,
    String? batchNumber,
    String? notes,
    DateTime? nextDueDate,
  }) async {
    return safeApiCall(() async {
      final response = await dio.post(
        '${ApiEndpoints.vaccinations}/$vaccinationId/administer',
        data: {
          'petId': petId,
          if (batchNumber != null) 'batchNumber': batchNumber,
          if (notes != null) 'notes': notes,
          if (nextDueDate != null)
            'nextDueDate': nextDueDate.toIso8601String(),
        },
      );
      return PetVaccinationModel.fromJson(response.data);
    });
  }
}
