import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/appointment_detail_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../data/models/models.dart';
import '../../../../data/providers/appointment_providers.dart';

class PetOwnerAppointmentsPage extends ConsumerStatefulWidget {
  const PetOwnerAppointmentsPage({super.key});

  @override
  ConsumerState<PetOwnerAppointmentsPage> createState() => _PetOwnerAppointmentsPageState();
}

class _PetOwnerAppointmentsPageState extends ConsumerState<PetOwnerAppointmentsPage> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Upcoming', 'Completed', 'Pending'];

  @override
  Widget build(BuildContext context) {
    // Fetch specifically the logged-in pet owner's appointments.
    final appointmentsAsync = ref.watch(myAppointmentsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'My Appointments',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Filter Pills
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
                            ),
                            child: Text(
                              _filters[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} Appointments',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: _buildAppointmentList(filtered),
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
        return appointments.where((a) => a.status == 'ACCEPTED' || a.status == 'RESCHEDULED').toList();
      case 1: // Completed
        return appointments.where((a) => a.status == 'COMPLETED').toList();
      case 2: // Pending
        return appointments.where((a) => a.status == 'PENDING').toList();
      default:
        return appointments;
    }
  }

  Widget _buildAppointmentList(List<AppointmentModel> filtered) {
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: 'No appointments',
        subtitle: 'You have no ${_filters[_selectedFilter].toLowerCase()} appointments',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myAppointmentsProvider(null).future),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _OwnerAppointmentListView(appointment: filtered[index]),
      ),
    );
  }
}

// Appointment List View specifically tuned for the Pet Owner
class _OwnerAppointmentListView extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const _OwnerAppointmentListView({required this.appointment});

  @override
  ConsumerState<_OwnerAppointmentListView> createState() => _OwnerAppointmentListViewState();
}

class _OwnerAppointmentListViewState extends ConsumerState<_OwnerAppointmentListView> {
  bool _isActing = false;

  Future<void> _performCancel() async {
    setState(() => _isActing = true);
    final notifier = ref.read(appointmentActionProvider.notifier);
    final success = await notifier.cancel(widget.appointment.id, reason: 'Cancelled by owner');

    if (!mounted) return;
    setState(() => _isActing = false);
    if (success) {
      AppToast.success(context, 'Appointment cancelled');
      ref.invalidate(myAppointmentsProvider);
    } else {
      AppToast.error(context, 'Failed to cancel appointment. Please try again.');
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep it')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performCancel();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  AppointmentModel get appointment => widget.appointment;

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
                  radius: 26,
                  backgroundColor: AppColors.inputFill,
                  child: appointment.pet?.name != null
                      ? Text(
                          appointment.pet!.name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                        )
                      : const Icon(Icons.pets, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.service?.name ?? 'Service',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'For: ${appointment.pet?.name ?? 'Unknown Pet'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(appointment.scheduledAt),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 16, color: AppColors.textMuted),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(appointment.scheduledAt),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (status == 'PENDING' || status == 'ACCEPTED') ...
              [
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isActing ? null : _showCancelDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isActing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2))
                        : const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
      case 'RESCHEDULED':
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
