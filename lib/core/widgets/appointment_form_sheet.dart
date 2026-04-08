import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/momo_payment_dialog.dart';
import '../../data/providers/service_providers.dart';
import '../../data/providers/pet_providers.dart';
import '../../data/providers/appointment_providers.dart';
import '../../data/providers/auth_providers.dart';
import '../../data/providers/payment_providers.dart';
import '../../data/models/models.dart';

/// Appointment Form Modal
class AppointmentFormSheet extends ConsumerStatefulWidget {
  final String? preselectedServiceId;
  final String? preselectedProviderId;
  final String? preselectedPetId;

  const AppointmentFormSheet({
    super.key,
    this.preselectedServiceId,
    this.preselectedProviderId,
    this.preselectedPetId,
  });

  static void show(BuildContext context, {String? serviceId, String? providerId, String? petId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentFormSheet(
        preselectedServiceId: serviceId,
        preselectedProviderId: providerId,
        preselectedPetId: petId,
      ),
    );
  }

  @override
  ConsumerState<AppointmentFormSheet> createState() => _AppointmentFormSheetState();
}

class _AppointmentFormSheetState extends ConsumerState<AppointmentFormSheet> {
  String? selectedServiceId;
  String? selectedPetId;
  DateTime selectedMonth = DateTime.now();
  int? selectedDay;
  TimeOfDay? selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedServiceId = widget.preselectedServiceId;
    selectedPetId = widget.preselectedPetId;
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(allServicesProvider(const ServiceQueryParams()));
    final myPetsAsync = ref.watch(myPetsProvider);

    // Generate days for the month
    final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
    final today = DateTime.now().day;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Center(
            child: Text(
              'Appointment Form',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // Service Dropdown
          const Text('Service', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Choose Service'),
                value: selectedServiceId,
                items: servicesAsync.value?.data.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                )).toList() ?? [],
                onChanged: (value) => setState(() => selectedServiceId = value),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date Picker
          const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
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
                onPressed: () => setState(() {
                  selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                  selectedDay = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final isSelected = selectedDay == day;
                final isPast = selectedMonth.month == DateTime.now().month && 
                               selectedMonth.year == DateTime.now().year && 
                               day < today;
                return GestureDetector(
                  onTap: isPast ? null : () => setState(() => selectedDay = day),
                  child: Container(
                    width: 45,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF21314C) : (isPast ? AppColors.inputFill : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? const Color(0xFF21314C) : AppColors.inputFill),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
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
          const SizedBox(height: 20),

          // Time Picker
          const Text('Select Time', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) setState(() => selectedTime = time);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   Icon(Icons.access_time, color: selectedTime != null ? AppColors.textPrimary : AppColors.textSecondary),
                   const SizedBox(width: 12),
                   Text(
                     selectedTime != null ? selectedTime!.format(context) : 'Choose Time',
                     style: TextStyle(
                       color: selectedTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                       fontSize: 16,
                     ),
                   ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Pet Dropdown
          const Text('Your Pet', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Choose from your pets'),
                value: selectedPetId,
                items: myPetsAsync.value?.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} (${p.petCode})'),
                )).toList() ?? [],
                onChanged: (value) => setState(() => selectedPetId = value),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Book Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedServiceId != null && selectedDay != null && selectedTime != null && selectedPetId != null && !_isLoading)
                  ? _submitAppointment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF21314C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAppointment() async {
    setState(() => _isLoading = true);

    final services = ref.read(allServicesProvider(const ServiceQueryParams())).value?.data ?? [];
    final service = services.cast<ServiceModel?>().firstWhere(
      (s) => s?.id == selectedServiceId,
      orElse: () => null,
    );

    final providerId = widget.preselectedProviderId ?? service?.providerId ?? '';

    // BUG 10: catch empty providerId before hitting the backend
    if (providerId.isEmpty) {
      setState(() => _isLoading = false);
      AppToast.error(context, 'Cannot determine the service provider. Please select a service again.');
      return;
    }

    final hour = selectedTime!.hour.toString().padLeft(2, '0');
    final minute = selectedTime!.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute';

    final resultPair = await ref.read(appointmentActionProvider.notifier).bookAppointment(
      serviceId: selectedServiceId!,
      providerId: providerId,
      scheduledDate: DateTime(selectedMonth.year, selectedMonth.month, selectedDay!),
      scheduledTime: timeString,
      petId: selectedPetId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      final appointment = resultPair.$1;
      final errorMsg = resultPair.$2;

      if (appointment != null) {
        ref.invalidate(myAppointmentsProvider);
        final price = appointment.servicePrice ?? 0;
        final paymentType = appointment.service?.paymentType ?? 'PAY_UPFRONT';

        // Only prompt for upfront payment immediately after booking.
        // PAY_AFTER services are paid once the appointment is completed.
        // SUBSCRIPTION services have no per-appointment charge.
        if (price > 0 && paymentType == 'PAY_UPFRONT') {
          // Show payment dialog BEFORE popping the sheet so the sheet context stays valid.
          // The dialog's callbacks close the sheet themselves.
          _showAppointmentPaymentDialog(context, ref, appointment.id, price);
        } else {
          Navigator.pop(context);
          AppToast.success(context, 'Appointment booked successfully!');
        }
      } else {
        AppToast.error(context, errorMsg ?? 'Failed to book appointment. Please try again.');
      }
    }
  }

  static void _showAppointmentPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    String appointmentId,
    double amount,
  ) {
    final user = ref.read(currentUserProvider);
    final mtnRegex = RegExp(r'^(078|079)\d{7}$');

    // Normalise profile phone to local format
    String? profilePhone;
    if (user?.phone != null && user!.phone!.isNotEmpty) {
      String phone = user.phone!;
      if (phone.startsWith('+250')) phone = '0${phone.substring(4)}';
      else if (phone.startsWith('250')) phone = '0${phone.substring(3)}';
      if (mtnRegex.hasMatch(phone)) profilePhone = phone;
    }

    // If a valid MTN number is already on file, skip the dialog and pay directly
    if (profilePhone != null) {
      _runPayment(context, ref, appointmentId, amount, profilePhone);
      return;
    }

    // No valid phone on file — show phone input dialog with Pay Later / Pay Now options
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
              'Amount due: ${amount.toStringAsFixed(0)} RWF',
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
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              AppToast.success(context, 'Appointment booked. Pay later from your appointments.');
            },
            child: const Text('Pay Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (!mtnRegex.hasMatch(phone)) {
                AppToast.error(dialogCtx, 'Enter a valid MTN number (078/079, 10 digits)');
                return;
              }
              Navigator.pop(dialogCtx);
              _runPayment(context, ref, appointmentId, amount, phone);
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

  static Future<void> _runPayment(BuildContext context, WidgetRef ref, String appointmentId, double amount, String phone) async {
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
        onRetry: () => _showAppointmentPaymentDialog(context, ref, appointmentId, amount),
        onDismiss: () => Navigator.pop(context),
      );
    }
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}
