import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../data/providers/appointment_providers.dart';
import '../provider_portal.dart';

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
      backgroundColor: AppColors.background,
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
                    backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(resolveImageUrl(user.avatarUrl!)) : null,
                    child: user.avatarUrl == null 
                        ? const Icon(Icons.person, size: 50, color: AppColors.secondary) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(roleDisplay, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
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
                            error: (_, _) => const Row(
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
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () => _showEditProfileSheet(context, ref),
                  ),
                  _MenuItem(
                    icon: Icons.design_services_outlined, 
                    label: 'My Services', 
                    onTap: () {
                       final portal = context.findAncestorStateOfType<ProviderPortalState>();
                       portal?.navigateToTab(1);
                    }
                  ),
                  _MenuItem(
                    icon: Icons.calendar_today_outlined, 
                    label: 'Appointments', 
                    onTap: () {
                       final portal = context.findAncestorStateOfType<ProviderPortalState>();
                       portal?.navigateToTab(2);
                    }
                  ),
                  _MenuItem(
                    icon: Icons.bar_chart_outlined, 
                    label: 'Reports', 
                    onTap: () {
                       final portal = context.findAncestorStateOfType<ProviderPortalState>();
                       portal?.navigateToTab(3);
                    }
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () => _showHelpSupport(context),
                  ),
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

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(ref: ref),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Help & Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _helpItem(Icons.email_outlined, 'Email', 'support@rwandapetlovers.com'),
            const SizedBox(height: 16),
            _helpItem(Icons.phone_outlined, 'Phone', '+250 788 000 000'),
            const SizedBox(height: 16),
            _helpItem(Icons.location_on_outlined, 'Address', 'Kigali, Rwanda'),
            const SizedBox(height: 16),
            _helpItem(Icons.access_time_outlined, 'Working Hours', 'Mon-Fri, 8:00 AM - 6:00 PM'),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
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
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _EditProfileSheet({required this.ref});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = widget.ref.read(currentUserProvider);
    _nameController.text = user?.fullName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUpdatingProfile ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUpdatingProfile
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            const Text('Current Password', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter current password',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
              ),
            ),
            const SizedBox(height: 12),

            const Text('New Password', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
              ),
            ),
            const SizedBox(height: 12),

            const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21314C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isChangingPassword
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastUtils.showError(context, 'Please enter your name');
      return;
    }
    setState(() => _isUpdatingProfile = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile({'fullName': name});
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) {
        ToastUtils.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ToastUtils.showError(context, 'Failed to update profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ToastUtils.showError(context, 'Please fill in all password fields');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ToastUtils.showError(context, 'New passwords do not match');
      return;
    }
    setState(() => _isChangingPassword = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );
      if (mounted) {
        ToastUtils.showSuccess(context, 'Password changed successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ToastUtils.showError(context, 'Failed to change password: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
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
