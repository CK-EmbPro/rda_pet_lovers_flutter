import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_detail_sheet.dart';
// import '../../../data/providers/mock_data_provider.dart'; // Removing
import '../../../data/models/models.dart';
import '../../../data/providers/appointment_providers.dart';

// Provider for appointments view mode (UI state only)
final appointmentsViewModeProvider = StateProvider<bool>((ref) => false); // false = list, true = card

class AppointmentsPage extends ConsumerStatefulWidget {
  const AppointmentsPage({super.key});

  @override
  ConsumerState<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends ConsumerState<AppointmentsPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Upcoming', 'Completed', 'Pending'];

  @override
  Widget build(BuildContext context) {
    // Fetch all provider appointments. 
    // Optimization: We could filter by status if we wanted to fetch only tab data, 
    // but for now fetching all allows smooth tab switching without loading.
    final appointmentsAsync = ref.watch(providerAppointmentsProvider(null));
    final isCardView = ref.watch(appointmentsViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointments',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your bookings',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 20),
                // Filter Pills - Improved styling per design
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = _selectedFilter == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              _filters[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? AppColors.secondary : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (paginated) {
                final appointments = paginated.data;
                final filtered = _getFilteredAppointments(appointments);

                return Column(
                  children: [
                    // View toggle and count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} Appointments',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              _ViewToggleButton(
                                icon: Icons.grid_view_rounded,
                                isSelected: isCardView,
                                onTap: () => ref.read(appointmentsViewModeProvider.notifier).state = true,
                              ),
                              const SizedBox(width: 8),
                              _ViewToggleButton(
                                icon: Icons.view_list_rounded,
                                isSelected: !isCardView,
                                onTap: () => ref.read(appointmentsViewModeProvider.notifier).state = false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // List
                    Expanded(
                      child: _buildAppointmentList(filtered, isCardView),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppointmentModel> _getFilteredAppointments(List<AppointmentModel> appointments) {
    switch (_selectedFilter) {
      case 0: // Upcoming
        return appointments.where((a) => a.status == 'CONFIRMED').toList();
      case 1: // Completed
        return appointments.where((a) => a.status == 'COMPLETED').toList();
      case 2: // Pending
        return appointments.where((a) => a.status == 'PENDING').toList();
      default:
        return appointments;
    }
  }

  Widget _buildAppointmentList(List<AppointmentModel> filtered, bool isCardView) {
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: 'No appointments',
        subtitle: 'You have no ${_filters[_selectedFilter].toLowerCase()} appointments',
      );
    }

    if (isCardView) {
      return RefreshIndicator(
        onRefresh: () => ref.refresh(providerAppointmentsProvider(null).future),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _AppointmentCardView(appointment: filtered[index]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(providerAppointmentsProvider(null).future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _AppointmentListView(appointment: filtered[index]),
      ),
    );
  }
}

// View Toggle Button
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.inputFill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// Appointment Card View (Grid)
class _AppointmentCardView extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCardView({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => AppointmentDetailSheet.show(context, appointment),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: statusColor,
                ),
              ),
            ),
            const Spacer(),
            // Pet avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.inputFill,
              child: appointment.pet?.name != null
                  ? Text(
                      appointment.pet!.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  : const Icon(Icons.pets, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            // Pet name
            Text(
              appointment.pet?.name ?? 'Unknown Pet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              appointment.pet?.breed ?? 'Unknown breed',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Date & Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(appointment.scheduledAt),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

// Appointment List View
class _AppointmentListView extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentListView({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final status = appointment.status;
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => AppointmentDetailSheet.show(context, appointment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.inputFill,
                  child: appointment.pet?.name != null
                      ? Text(
                          appointment.pet!.name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : const Icon(Icons.pets, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.pet?.name ?? 'Unknown Pet',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        appointment.pet?.breed ?? 'Unknown',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(appointment.scheduledAt),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(appointment.scheduledAt),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Accept/Decline Logic can be implemented here using AppointmentActionNotifier
            // For now, let's leave it as is, or use the Sheet for actions
          ],
        ),
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
