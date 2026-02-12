import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/appointment_providers.dart';

class ProviderProfilePage extends ConsumerWidget {
  const ProviderProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDoctor = user.roles.any((r) => r == 'VET_DOCTOR' || r == 'VETERINARY');
    final roleDisplay = isDoctor ? 'Veterinary Doctor' : 'Pet Service Provider';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null 
                        ? const Icon(Icons.person, size: 50, color: AppColors.secondary) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(roleDisplay, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 16),
                      // Real Stats Calculation
                      Consumer(
                        builder: (context, ref, child) {
                          final appointmentsAsync = ref.watch(providerAppointmentsProvider(null));
                          
                          return appointmentsAsync.when(
                            data: (paginated) {
                              final appointments = paginated.data;
                              // Calculate unique clients
                              final uniqueClients = appointments
                                  .map((a) => a.userId)
                                  .toSet()
                                  .length;
                              
                              // Calculate experience (years since registration)
                              final experienceYears = DateTime.now().difference(user.createdAt).inDays ~/ 365;
                              final experienceText = experienceYears > 0 ? '$experienceYears yrs' : '<1 yr';

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _StatItem(label: 'Rating', value: 'New'), // Placeholder until ratings API exists
                                  _StatItem(label: 'Clients', value: '$uniqueClients'),
                                  _StatItem(label: 'Experience', value: experienceText),
                                ],
                              );
                            },
                            loading: () => const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatItem(label: 'Rating', value: 'New'),
                                _StatItem(label: 'Clients', value: '0'),
                                _StatItem(label: 'Experience', value: '0'),
                              ],
                            ),
                            error: (_, __) => const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatItem(label: 'Rating', value: 'New'),
                                _StatItem(label: 'Clients', value: '0'),
                                _StatItem(label: 'Experience', value: '0'),
                              ],
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
            // Menu Items
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _MenuItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
                  _MenuItem(icon: Icons.design_services_outlined, label: 'My Services', onTap: () {
                     // Evaluate if this navigation is needed since tab 1 is services. 
                     // Maybe it should switch tab? But for now leaving as placeholder action.
                  }),
                  _MenuItem(icon: Icons.calendar_today_outlined, label: 'Appointments', onTap: () {}),
                  _MenuItem(icon: Icons.monetization_on_outlined, label: 'Earnings', onTap: () {}),
                  _MenuItem(icon: Icons.schedule_outlined, label: 'Availability', onTap: () {}),
                  _MenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
                  _MenuItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
                  const SizedBox(height: 20),
                  _MenuItem(
                    icon: Icons.logout, 
                    label: 'Logout', 
                    isDestructive: true, 
                    onTap: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
        title: Text(label, style: TextStyle(color: isDestructive ? AppColors.error : AppColors.textPrimary, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: isDestructive ? AppColors.error : AppColors.textMuted),
      ),
    );
  }
}
