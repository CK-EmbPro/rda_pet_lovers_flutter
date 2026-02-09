import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/appointment_detail_sheet.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';
import '../provider_portal.dart';
import 'my_services_page.dart';

// Provider appointments for the current provider
final providerAppointmentsProvider = Provider<List<AppointmentModel>>((ref) {
  // Mock appointments for the provider
  return mockAppointments;
});

class ProviderDashboardPage extends ConsumerStatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final appointments = ref.watch(providerAppointmentsProvider);
    
    // Filter appointments
    final today = DateTime.now();
    final todaysAppointments = appointments.where((a) {
      return a.scheduledAt.year == today.year &&
             a.scheduledAt.month == today.month &&
             a.scheduledAt.day == today.day &&
             (a.status == 'CONFIRMED' || a.status == 'PENDING');
    }).toList();
    
    final pendingRequests = appointments.where((a) => a.status == 'PENDING').toList();
    final thisMonthAccepted = appointments.where((a) {
      return a.scheduledAt.month == today.month &&
             a.scheduledAt.year == today.year &&
             a.status == 'CONFIRMED';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, user),
              const SizedBox(height: 16),
              
              // Stats Row
              _buildStatsRow(todaysAppointments.length, appointments.length, thisMonthAccepted.length),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),
              
              // Calendar
              _buildCalendarSection(),
              const SizedBox(height: 24),
              
              // Today's Schedule
              _buildTodaysSchedule(todaysAppointments),
              const SizedBox(height: 24),
              
              // Appointment Requests
              _buildAppointmentRequests(pendingRequests),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    final isDoctor = user?.roles.any((r) => r == 'VET_DOCTOR' || r == 'VETERINARY') ?? false;
    final displayName = user?.fullName ?? 'Provider';
    final greeting = isDoctor ? 'Welcome back Dr.' : 'Welcome back,';
    
    // Get initials for avatar
    final nameParts = displayName.split(' ');
    final initials = nameParts.length >= 2 
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : displayName.substring(0, 2).toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppTypography.bodySmall),
                const SizedBox(height: 4),
                Text(displayName, style: AppTypography.h2),
                if (isDoctor) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Kigali Veterinary Hospital',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              // Notifications
              GestureDetector(
                onTap: () => NotificationsSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Badge(
                    label: const Text('3'),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Profile with initials
              GestureDetector(
                onTap: () {
                  final portal = context.findAncestorStateOfType<ProviderPortalState>();
                  portal?.navigateToTab(3); // Profile tab
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int todayCount, int weekCount, int monthCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(icon: Icons.calendar_today, value: '$todayCount', label: 'Today', color: AppColors.secondary),
          const SizedBox(width: 8),
          _StatCard(icon: Icons.date_range, value: '$weekCount', label: 'This Week', color: Colors.orange),
          const SizedBox(width: 8),
          _StatCard(icon: Icons.check_circle_outline, value: '$monthCount', label: 'This Month', color: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Create Service',
                color: AppColors.secondary,
                onTap: () => _showAddServiceSheet(context),
              ),
              _QuickActionButton(
                icon: Icons.event_available,
                label: 'Set Availability',
                color: AppColors.success,
                onTap: () {
                  final portal = context.findAncestorStateOfType<ProviderPortalState>();
                  portal?.navigateToTab(1); // Services tab
                },
              ),
              _QuickActionButton(
                icon: Icons.pending_actions,
                label: 'View Requests',
                color: Colors.orange,
                onTap: () {
                  final portal = context.findAncestorStateOfType<ProviderPortalState>();
                  portal?.navigateToTab(2); // Appointments tab (pending)
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddServiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text('Create New Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const AppTextField(label: 'Service Name', hint: 'e.g: Pet Grooming', prefixIcon: Icons.design_services),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: AppTextField(label: 'Price (RWF)', hint: '25000', prefixIcon: Icons.monetization_on)),
                SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Duration', hint: '1 hour', prefixIcon: Icons.timer)),
              ],
            ),
            const SizedBox(height: 16),
            const AppTextField(label: 'Description', hint: 'Describe your service...', prefixIcon: Icons.description),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create Service', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: AppColors.secondary),
              markerDecoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              weekendStyle: TextStyle(color: AppColors.secondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule(List<AppointmentModel> appointments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {
                  final portal = context.findAncestorStateOfType<ProviderPortalState>();
                  portal?.navigateToTab(2);
                },
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        if (appointments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Center(
                child: Text('No appointments scheduled for today', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: appointments.take(3).length,
            itemBuilder: (context, index) {
              final apt = appointments[index];
              return _ScheduleCard(appointment: apt);
            },
          ),
      ],
    );
  }

  Widget _buildAppointmentRequests(List<AppointmentModel> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Appointment Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () {
                  final portal = context.findAncestorStateOfType<ProviderPortalState>();
                  portal?.navigateToTab(2);
                },
                child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ),
        if (requests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Center(
                child: Text('No pending requests', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: requests.take(3).length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RequestCard(appointment: request);
            },
          ),
      ],
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// Schedule Card Widget
class _ScheduleCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _ScheduleCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final timeString = '${appointment.scheduledAt.hour}:${appointment.scheduledAt.minute.toString().padLeft(2, '0')} ${appointment.scheduledAt.hour >= 12 ? 'PM' : 'AM'}';
    
    return GestureDetector(
      onTap: () => AppointmentDetailSheet.show(
        context,
        appointment,
        userType: AppointmentUserType.provider,
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.inputFill,
            child: appointment.pet?.name != null
                ? Text(
                    appointment.pet!.name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
                  appointment.pet?.breed ?? 'Unknown breed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  timeString,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_forward, color: AppColors.secondary, size: 20),
          ),
        ],
      ),
      ),
    );
  }
}

// Request Card Widget
class _RequestCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _RequestCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppointmentDetailSheet.show(
        context,
        appointment,
        userType: AppointmentUserType.provider,
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.inputFill,
            child: appointment.pet?.name != null
                ? Text(
                    appointment.pet!.name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
                  appointment.pet?.breed ?? 'Unknown breed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_forward, color: Colors.orange, size: 20),
          ),
        ],
      ),
      ),
    );
  }
}
