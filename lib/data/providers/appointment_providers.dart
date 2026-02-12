import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../models/models.dart';
import '../services/appointment_service.dart';
import '../services/pet_service.dart';

/// Singleton AppointmentService provider
final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(DioClient());
});

/// My appointments (pet owner)
final myAppointmentsProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<AppointmentModel>, String?>(
        (ref, status) async {
  final service = ref.read(appointmentServiceProvider);
  return service.getMyAppointments(status: status);
});

/// Provider appointments (service provider)
final providerAppointmentsProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<AppointmentModel>, String?>(
        (ref, status) async {
  final service = ref.read(appointmentServiceProvider);
  return service.getProviderAppointments(status: status);
});

/// Single appointment detail
final appointmentDetailProvider = FutureProvider.autoDispose
    .family<AppointmentModel, String>((ref, id) async {
  final service = ref.read(appointmentServiceProvider);
  return service.getById(id);
});

/// Appointment action notifier (book, accept, reject, complete, cancel, reschedule)
class AppointmentActionNotifier extends StateNotifier<AsyncValue<void>> {
  final AppointmentService _service;

  AppointmentActionNotifier(this._service)
      : super(const AsyncValue.data(null));

  Future<AppointmentModel?> bookAppointment({
    required String serviceId,
    required String providerId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? petId,
    String? customerNotes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final appointment = await _service.create(
        serviceId: serviceId,
        providerId: providerId,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        petId: petId,
        customerNotes: customerNotes,
      );
      state = const AsyncValue.data(null);
      return appointment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> accept(String id, {String? providerNotes}) async {
    state = const AsyncValue.loading();
    try {
      await _service.accept(id, providerNotes: providerNotes);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reject(String id, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.reject(id, reason: reason);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> complete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _service.complete(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancel(String id, {String? reason}) async {
    state = const AsyncValue.loading();
    try {
      await _service.cancel(id, reason: reason);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reschedule(String id,
      {required DateTime newDate, required String newTime}) async {
    state = const AsyncValue.loading();
    try {
      await _service.reschedule(id, newDate: newDate, newTime: newTime);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final appointmentActionProvider =
    StateNotifierProvider<AppointmentActionNotifier, AsyncValue<void>>((ref) {
  return AppointmentActionNotifier(ref.read(appointmentServiceProvider));
});
