import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/providers/appointment_providers.dart';
import '../../data/models/models.dart';

/// All Appointments Sheet - Opens like NotificationsSheet
class AllAppointmentsSheet extends ConsumerWidget {
  const AllAppointmentsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AllAppointmentsSheet(),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return AppColors.error;
      case 'COMPLETED':
        return AppColors.secondary;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(myAppointmentsProvider(null));
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Appointments',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    appointmentsAsync.when(
                      data: (paginated) => Text(
                        '${paginated.data.length} appointments',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Appointments List
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (paginated) {
                final appointments = paginated.data;
                if (appointments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: AppColors.inputFill),
                        SizedBox(height: 16),
                        Text('No appointments yet', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final apt = appointments[index];
                    return _AppointmentItem(apt: apt, getStatusColor: _getStatusColor, formatDate: _formatDate, formatTime: _formatTime);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentItem extends StatelessWidget {
  final AppointmentModel apt;
  final Function(String) getStatusColor;
  final Function(DateTime) formatDate;
  final Function(DateTime) formatTime;

  const _AppointmentItem({required this.apt, required this.getStatusColor, required this.formatDate, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputFill),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.secondary.withAlpha(25),
            backgroundImage: apt.provider?.avatarUrl != null
                ? NetworkImage(apt.provider!.avatarUrl!)
                : null,
            child: apt.provider?.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.secondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider Name
                Text(
                  apt.provider?.fullName ?? 'Service Provider',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                // Pet Name
                if (apt.pet != null)
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        apt.pet!.name,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Date and Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(apt.scheduledAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      formatTime(apt.scheduledAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor(apt.status).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              apt.status,
              style: TextStyle(
                color: getStatusColor(apt.status),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
