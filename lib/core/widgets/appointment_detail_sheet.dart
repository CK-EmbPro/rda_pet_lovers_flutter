import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/appointment_providers.dart';

/// Enum to distinguish user types for different action buttons
enum AppointmentUserType { provider, petOwner }

/// A modal sheet that shows appointment details when an appointment card is clicked
class AppointmentDetailSheet extends ConsumerWidget {
  final AppointmentModel appointment;
  final AppointmentUserType userType;

  const AppointmentDetailSheet({
    super.key,
    required this.appointment,
    this.userType = AppointmentUserType.provider,
  });

  static void show(BuildContext context, AppointmentModel appointment, {AppointmentUserType userType = AppointmentUserType.provider}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => AppointmentDetailSheet(
          appointment: appointment,
          userType: userType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(appointment.status);
    final formattedDate = _formatDate(appointment.scheduledAt);
    final formattedTime = _formatTime(appointment.scheduledAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header with status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Appointment Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Pet & Client Info
            _buildSection(
              icon: Icons.pets,
              title: 'Pet Information',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name', appointment.pet?.name ?? 'Unknown'),
                  _buildInfoRow('Breed', appointment.pet?.breed ?? 'Unknown'),
                  _buildInfoRow('Pet Code', appointment.pet?.petCode ?? 'N/A'),
                ],
              ),
            ),
            const Divider(height: 32),
            
            // Provider/Service Info (for pet owner)
            if (userType == AppointmentUserType.petOwner) ...[
              _buildSection(
                icon: Icons.medical_services,
                title: 'Service Provider',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Provider', appointment.provider?.fullName ?? 'Unknown'),
                    _buildInfoRow('Service', appointment.service?.name ?? 'Unknown'),
                  ],
                ),
              ),
              const Divider(height: 32),
            ],
            
            // Appointment Info
            _buildSection(
              icon: Icons.calendar_today,
              title: 'Schedule',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Date', formattedDate),
                  _buildInfoRow('Time', formattedTime),
                  _buildInfoRow('Duration', '${appointment.durationMinutes} minutes'),
                ],
              ),
            ),
            const Divider(height: 32),
            
            // Payment Info
            _buildSection(
              icon: Icons.payment,
              title: 'Payment',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Amount', '${appointment.totalAmount?.toInt() ?? 0} RWF'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Actions based on user type and status
            _buildActionButtons(context, ref),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    if (userType == AppointmentUserType.provider) {
      // Provider actions
      if (appointment.status == 'PENDING') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectReasonDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await ref.read(appointmentActionProvider.notifier).accept(appointment.id);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(providerAppointmentsProvider);
                      AppToast.success(context, 'Appointment accepted');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      } else if (appointment.status == 'CONFIRMED') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final success = await ref.read(appointmentActionProvider.notifier).complete(appointment.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(providerAppointmentsProvider);
                  AppToast.success(context, 'Marked as complete');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Mark as Complete', style: TextStyle(color: Colors.white)),
            ),
          ),
        );
      }
    } else {
      // Pet owner actions
      if (appointment.status == 'PENDING') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final success = await ref.read(appointmentActionProvider.notifier).cancel(appointment.id);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(myAppointmentsProvider);
                      AppToast.success(context, 'Appointment cancelled');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context), // TODO: Reschedule
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Re-schedule', style: TextStyle(color: Colors.white)), // Placeholder
                ),
              ),
            ],
          ),
        );
      } else if (appointment.status == 'CONFIRMED') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
               onPressed: () async {
                final success = await ref.read(appointmentActionProvider.notifier).cancel(appointment.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(myAppointmentsProvider);
                  AppToast.success(context, 'Appointment cancelled');
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel Appointment', style: TextStyle(color: AppColors.error)),
            ),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _showRejectReasonDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this appointment:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                final success = await ref.read(appointmentActionProvider.notifier).reject(
                  appointment.id, 
                  reason: reasonController.text.trim()
                );
                
                if (success && context.mounted) {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pop(context); // Close detail sheet
                  ref.invalidate(providerAppointmentsProvider);
                  AppToast.error(context, 'Appointment rejected');
                }

              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'PENDING':
        return Colors.orange;
      case 'COMPLETED':
        return AppColors.secondary;
      case 'CANCELLED':
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
