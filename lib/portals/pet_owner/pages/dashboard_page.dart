import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final myPets = ref.watch(myPetsProvider);
    final services = ref.watch(servicesProvider);
    final appointments = ref.watch(myAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back,', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text(user?.fullName ?? 'Pet Owner', style: AppTypography.h2),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: () {},
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.inputFill,
                          backgroundImage: user?.avatarUrl != null
                              ? CachedNetworkImageProvider(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? const Icon(Icons.person, color: AppColors.textSecondary)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Actions
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
                    _QuickActionButton(icon: Icons.pets, label: 'Add Pet', color: AppColors.secondary, onTap: () {}),
                    _QuickActionButton(icon: Icons.compare_arrows, label: 'Mate Check', color: AppColors.success, onTap: () => _showMateCheckModal(context, ref)),
                    _QuickActionButton(icon: Icons.medical_services, label: 'Book Vet', color: Colors.orange, onTap: () {}),
                    _QuickActionButton(icon: Icons.store, label: 'Shop', color: Colors.purple, onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // My Pets Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Pets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
                    ),
                  ],
                ),
              ),
              myPets.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets, size: 40, color: AppColors.textMuted),
                              SizedBox(height: 8),
                              Text('No pets registered yet', style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.92),
                        itemCount: myPets.length,
                        itemBuilder: (context, index) {
                          final pet = myPets[index];
                          return _PetSlideCard(
                            pet: pet,
                            onMateCheck: () => _showMateCheckModalForPet(context, pet),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 24),

              // Upcoming Appointments
              if (appointments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Upcoming Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                ...appointments.take(2).map((apt) => _AppointmentCard(appointment: apt)),
                const SizedBox(height: 24),
              ],

              // Available Services
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Available Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              ...services.take(3).map((service) => _ServiceTile(service: service)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showMateCheckModal(BuildContext context, WidgetRef ref) {
    final myPets = ref.read(myPetsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Mate Compatibility Check', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Check if two pets are compatible for mating by comparing their parents and grandparents.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Your Pet Code',
              hint: myPets.isNotEmpty ? myPets.first.petCode : 'PET-XXX-XXX',
              prefixIcon: Icons.pets,
            ),
            const SizedBox(height: 16),
            const AppTextField(label: 'Partner Pet Code', hint: 'Enter partner pet code', prefixIcon: Icons.pets),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Check Compatibility',
              onPressed: () {
                Navigator.pop(context);
                _showCompatibilityResult(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMateCheckModalForPet(BuildContext context, PetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Mate Compatibility Check', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.pets, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text('Checking for: ${pet.name}', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Code: ${pet.petCode}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            const AppTextField(label: 'Partner Pet Code', hint: 'Enter partner pet code', prefixIcon: Icons.pets),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Check Compatibility',
              onPressed: () {
                Navigator.pop(context);
                _showCompatibilityResult(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCompatibilityResult(BuildContext context, bool isCompatible) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompatible ? Icons.check_circle : Icons.cancel,
              size: 60,
              color: isCompatible ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isCompatible ? 'Compatible!' : 'Not Compatible',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isCompatible
                  ? 'These pets have no matching parents or grandparents and are safe for mating.'
                  : 'These pets share common ancestors and should not be mated.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
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

class _PetSlideCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onMateCheck;
  const _PetSlideCard({required this.pet, required this.onMateCheck});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Pet Image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: pet.displayImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: pet.displayImage,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.inputFill),
                    errorWidget: (_, __, ___) => _petPlaceholder(),
                  )
                : _petPlaceholder(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(pet.breed?.name ?? pet.species?.name ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(pet.petCode, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: AppColors.success),
            onPressed: onMateCheck,
            tooltip: 'Mate Check',
          ),
        ],
      ),
    );
  }

  Widget _petPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.inputFill,
      child: const Icon(Icons.pets, size: 40, color: AppColors.secondary),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
            backgroundImage: appointment.provider?.avatarUrl != null
                ? CachedNetworkImageProvider(appointment.provider!.avatarUrl!)
                : null,
            child: appointment.provider?.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.provider?.fullName ?? 'Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(appointment.service?.name ?? 'Service', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${appointment.scheduledAt.day}/${appointment.scheduledAt.month} at ${appointment.scheduledAt.hour}:${appointment.scheduledAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(label: appointment.displayStatus, isPositive: appointment.isConfirmed),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
            backgroundImage: service.provider?.avatarUrl != null
                ? CachedNetworkImageProvider(service.provider!.avatarUrl!)
                : null,
            child: service.provider?.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.provider?.fullName ?? 'Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(service.displayServiceType, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(label: 'Available', isPositive: true),
        ],
      ),
    );
  }
}
