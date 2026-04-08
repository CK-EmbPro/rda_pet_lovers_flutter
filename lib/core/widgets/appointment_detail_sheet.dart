import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/momo_payment_dialog.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/appointment_providers.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/providers/payment_providers.dart';

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
                  _buildInfoRow('Amount', '${(appointment.servicePrice ?? appointment.totalAmount ?? 0).toInt()} RWF'),
                  _buildInfoRow('Payment', appointment.service?.paymentTypeLabel ?? 'Pay Upfront'),
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
    final status = appointment.status;

    if (userType == AppointmentUserType.provider) {
      // PENDING or RESCHEDULED → provider can accept or reject
      if (status == 'PENDING' || status == 'RESCHEDULED') {
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }

      // ACCEPTED → provider can mark complete
      if (status == 'ACCEPTED') {
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mark as Complete', style: TextStyle(color: Colors.white)),
            ),
          ),
        );
      }
    } else {
      final price = appointment.servicePrice ?? appointment.totalAmount ?? 0;
      final paymentType = appointment.service?.paymentType ?? 'PAY_UPFRONT';

      // Pet owner: PENDING or ACCEPTED → cancel + reschedule
      if (status == 'PENDING' || status == 'ACCEPTED') {
        // PAY_UPFRONT: show payment button while PENDING (before provider accepts)
        final showPayNow = price > 0 && status == 'PENDING' && paymentType == 'PAY_UPFRONT';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRescheduleDialog(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Re-schedule', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              if (showPayNow) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPayNowDialog(context, ref, appointment.id, price),
                    icon: const Icon(Icons.payment, color: Colors.white, size: 18),
                    label: Text('Pay Now — ${price.toStringAsFixed(0)} RWF', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      // PAY_AFTER: appointment is done — backend already sent MoMo push if phone was on file.
      // Show an info banner + a manual fallback button in case they missed the phone prompt.
      if (status == 'COMPLETED' && price > 0 && paymentType == 'PAY_AFTER') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.phone_android_rounded, color: AppColors.secondary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A payment request was sent to your phone. Check your MoMo messages to approve.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showPayNowDialog(context, ref, appointment.id, price),
                  icon: const Icon(Icons.payment, size: 18),
                  label: Text('Pay manually — ${price.toStringAsFixed(0)} RWF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  void _showPayNowDialog(BuildContext context, WidgetRef ref, String appointmentId, double amount) {
    final user = ref.read(currentUserProvider);
    final mtnRegex = RegExp(r'^(078|079)\d{7}$');

    // Normalise profile phone to local format (078/079XXXXXXX)
    String? profilePhone;
    if (user?.phone != null && user!.phone!.isNotEmpty) {
      String phone = user.phone!;
      if (phone.startsWith('+250')) phone = '0${phone.substring(4)}';
      else if (phone.startsWith('250')) phone = '0${phone.substring(3)}';
      if (mtnRegex.hasMatch(phone)) profilePhone = phone;
    }

    // If a valid MTN number is already on file, skip the dialog and pay directly
    if (profilePhone != null) {
      _runMomoPayment(context, ref, appointmentId, amount, profilePhone);
      return;
    }

    // No valid phone on file — show phone input dialog
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pay for Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${amount.toStringAsFixed(0)} RWF',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('MTN MoMo Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '078 XXX XXXX',
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
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (!mtnRegex.hasMatch(phone)) {
                AppToast.error(dialogCtx, 'Enter a valid MTN number (078/079, 10 digits)');
                return;
              }
              Navigator.pop(dialogCtx);
              _runMomoPayment(context, ref, appointmentId, amount, phone);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Pay Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _runMomoPayment(BuildContext context, WidgetRef ref, String appointmentId, double amount, String phone) async {
    await ref.read(momoPaymentProvider.notifier).payForAppointment(
      appointmentId: appointmentId,
      amount: amount,
      phoneNumber: phone,
    );
    if (context.mounted) {
      MomoPaymentStatusDialog.show(
        context,
        onSuccess: () {
          ref.invalidate(myAppointmentsProvider);
          Navigator.pop(context);
        },
        onRetry: () => _showPayNowDialog(context, ref, appointmentId, amount),
        onDismiss: () {},
      );
    }
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

  void _showRescheduleDialog(BuildContext context, WidgetRef ref) {
    DateTime selectedMonth = DateTime.now();
    int? selectedDay;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
          final today = DateTime.now();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Re-schedule Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month navigator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setDialogState(() {
                          selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                          selectedDay = null;
                        }),
                      ),
                      Text(
                        '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setDialogState(() {
                          selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                          selectedDay = null;
                        }),
                      ),
                    ],
                  ),
                  // Day row
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: daysInMonth,
                      itemBuilder: (_, index) {
                        final day = index + 1;
                        final isSelected = selectedDay == day;
                        final isPast = selectedMonth.year == today.year &&
                            selectedMonth.month == today.month &&
                            day < today.day;
                        return GestureDetector(
                          onTap: isPast ? null : () => setDialogState(() => selectedDay = day),
                          child: Container(
                            width: 40,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : (isPast ? AppColors.inputFill : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.inputFill),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : (isPast ? AppColors.textMuted : AppColors.textPrimary),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Time picker
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: dialogCtx,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) setDialogState(() => selectedTime = time);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: selectedTime != null ? AppColors.textPrimary : AppColors.textSecondary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            selectedTime != null ? selectedTime!.format(dialogCtx) : 'Choose new time',
                            style: TextStyle(color: selectedTime != null ? AppColors.textPrimary : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedDay == null || selectedTime == null)
                    ? null
                    : () async {
                        final newDate = DateTime(selectedMonth.year, selectedMonth.month, selectedDay!);
                        final hour = selectedTime!.hour.toString().padLeft(2, '0');
                        final minute = selectedTime!.minute.toString().padLeft(2, '0');
                        final newTime = '$hour:$minute';

                        final success = await ref.read(appointmentActionProvider.notifier)
                            .reschedule(appointment.id, newDate: newDate, newTime: newTime);

                        if (context.mounted) {
                          Navigator.pop(dialogCtx);
                          Navigator.pop(context); // close detail sheet
                          if (success) {
                            ref.invalidate(myAppointmentsProvider);
                            AppToast.success(context, 'Appointment rescheduled');
                          } else {
                            AppToast.error(context, 'Failed to reschedule. Please try again.');
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
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
      case 'ACCEPTED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'RESCHEDULED':
        return AppColors.secondary;
      case 'COMPLETED':
        return const Color(0xFF6366F1); // indigo
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
