import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/filter_sheet.dart';
import '../../../core/widgets/notifications_sheet.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';
import '../pet_owner_portal.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final services = ref.watch(servicesProvider);
    final appointments = ref.watch(myAppointmentsProvider);
    final shops = ref.watch(shopsProvider);
    final browsablePets = ref.watch(browsablePetsProvider);

    // Split browsable pets by listing type
    final petsForSale = browsablePets.where((p) => p.listingType == 'FOR_SALE').toList();
    final petsForDonation = browsablePets.where((p) => p.listingType == 'FOR_DONATION').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with notification and profile
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
                        // Notification Icon
                        GestureDetector(
                          onTap: () => NotificationsSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                                Positioned(
                                  right: 0,
                                  top: 0,
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile Icon - Links to Profile Page
                        GestureDetector(
                          onTap: () {
                            final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                            portal?.navigateToTab(3);
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.inputFill,
                            backgroundImage: user?.avatarUrl != null
                                ? CachedNetworkImageProvider(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? const Icon(Icons.person, color: AppColors.textSecondary)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar with Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search pets, services, shops...',
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => FilterSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                    _QuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: '', // Removed as per request
                      color: AppColors.secondary,
                      onTap: () {
                        final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                        portal?.navigateToTab(1); // Go to My Pets page
                      },
                    ),
                    _QuickActionButton(icon: Icons.compare_arrows, label: 'Mate Check', color: AppColors.success, onTap: () => _showMateCheckModal(context, ref)),
                    _QuickActionButton(icon: Icons.calendar_today, label: 'Book Vet', color: Colors.orange, onTap: () => AppointmentFormSheet.show(context)),
                    _QuickActionButton(
                      icon: Icons.store,
                      label: 'Shop',
                      color: Colors.purple,
                      onTap: () {
                        final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                        portal?.navigateToTab(2);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upcoming Appointments
              if (appointments.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Upcoming Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                ),
                ...appointments.take(2).map((apt) => _AppointmentCard(appointment: apt)),
                const SizedBox(height: 24),
              ],

              // Shops Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shops Near You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {
                        final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                        portal?.navigateToTab(2);
                      },
                      child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final shop = shops[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.inputFill,
                                backgroundImage: shop.logoUrl != null
                                    ? CachedNetworkImageProvider(shop.logoUrl!)
                                    : null,
                                child: shop.logoUrl == null
                                    ? const Icon(Icons.store, color: AppColors.secondary)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  shop.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text('${shop.rating ?? 4.5}', style: const TextStyle(fontSize: 12)),
                              const Spacer(),
                              Text('${shop.productCount} items', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Being Sold Section
              if (petsForSale.isNotEmpty) ...[
                _buildPetsSectionHeader(context, 'Being Sold', () {
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                  portal?.navigateToTab(2);
                }),
                _buildPetsHorizontalList(petsForSale.take(5).toList()),
                const SizedBox(height: 24),
              ],

              // Being Donated Section
              if (petsForDonation.isNotEmpty) ...[
                _buildPetsSectionHeader(context, 'Being Donated', () {
                  final portal = context.findAncestorStateOfType<PetOwnerPortalState>();
                  portal?.navigateToTab(2);
                }),
                _buildPetsHorizontalList(petsForDonation.take(5).toList()),
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

  Widget _buildPetsSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsHorizontalList(List<PetModel> pets) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: pet.displayImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: pet.displayImage,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: AppColors.inputFill),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.inputFill,
                                  child: const Icon(Icons.pets, size: 30, color: AppColors.secondary),
                                ),
                              )
                            : Container(
                                color: AppColors.inputFill,
                                child: const Center(child: Icon(Icons.pets, size: 30, color: AppColors.secondary)),
                              ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: pet.listingType == 'FOR_SALE' ? AppColors.secondary : Colors.pink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pet.listingType == 'FOR_SALE' ? 'Sale' : 'Free',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                        Text(pet.breed?.name ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        if (pet.price != null && pet.price! > 0)
                          Text('${pet.price!.toInt()} RWF', style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
            if (label.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: () => AppointmentFormSheet.show(context, serviceId: service.id),
      child: Container(
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
            const StatusBadge(label: 'Available', isPositive: true),
          ],
        ),
      ),
    );
  }
}
