import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_detail_sheet.dart';
import '../../../core/widgets/app_toast.dart';
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
    final appointmentsAsync = ref.watch(providerAppointmentsProvider(null));
    final isCardView = ref.watch(appointmentsViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
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
                const Text(
                  'Appointments',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your bookings',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 24),
                // Filter Pills - Improved styling per design
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
                    // View toggle and count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filtered.length} Appointments',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
            childAspectRatio: 0.82,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: AppColors.border),
           boxShadow: isSelected ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: Colors.transparent),
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
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: statusColor,
                ),
              ),
            ),
            const Spacer(),
            // Pet avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.inputFill,
                  child: appointment.pet?.name != null
                      ? Text(
                          appointment.pet!.name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        )
                      : const Icon(Icons.pets, color: AppColors.textSecondary, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.pet?.name ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        appointment.pet?.breed ?? '--',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date & Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_formatDate(appointment.scheduledAt)}, ${_formatTime(appointment.scheduledAt)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

// Appointment List View
class _AppointmentListView extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const _AppointmentListView({required this.appointment});

  @override
  ConsumerState<_AppointmentListView> createState() => _AppointmentListViewState();
}

class _AppointmentListViewState extends ConsumerState<_AppointmentListView> {
  bool _isActing = false;

  Future<void> _performAction(String action, {String? reason}) async {
    setState(() => _isActing = true);
    final notifier = ref.read(appointmentActionProvider.notifier);
    bool success = false;
    String successMsg = '';

    switch (action) {
      case 'accept':
        success = await notifier.accept(widget.appointment.id);
        successMsg = 'Appointment accepted! ✅';
        break;
      case 'reject':
        success = await notifier.reject(widget.appointment.id, reason: reason ?? 'Not available');
        successMsg = 'Appointment rejected';
        break;
      case 'complete':
        success = await notifier.complete(widget.appointment.id);
        successMsg = 'Appointment marked as completed! 🎉';
        break;
    }

    if (!mounted) return;
    setState(() => _isActing = false);
    if (success) {
      AppToast.success(context, successMsg);
      ref.invalidate(providerAppointmentsProvider);
    } else {
      AppToast.error(context, 'Action failed. Please try again.');
    }
  }

  void _showRejectDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'e.g. Not available that day',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performAction('reject', reason: reasonCtrl.text);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
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
                        appointment.pet?.name ?? 'Unknown Pet',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        appointment.pet?.breed ?? 'Unknown Breed',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
            // Action buttons for PENDING and CONFIRMED appointments
            if (status == 'PENDING') ...
              [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isActing ? null : _showRejectDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isActing ? null : () => _performAction('accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isActing
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            if (status == 'CONFIRMED') ...
              [
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isActing ? null : () => _performAction('complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isActing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Mark as Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

