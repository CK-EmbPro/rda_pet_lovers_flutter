import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../data/models/models.dart';
// import '../../../data/providers/mock_data_provider.dart'; // Removing
import '../../../data/providers/service_providers.dart';

class ServiceDetailsPage extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailsPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return serviceAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load service details: $e')),
      ),
      data: (service) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(context, service),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServiceInfo(service),
                      const SizedBox(height: 32),
                      _buildProviderInfo(service.provider),
                      const SizedBox(height: 32),
                      _buildDescription(service.description),
                      const SizedBox(height: 40),
                      _buildActionButtons(context, service),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ServiceModel service) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  _getIconForType(service.serviceType),
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  service.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  service.displayServiceType,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo(ServiceModel service) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _InfoItem(
          icon: Icons.payments_outlined,
          label: 'Fee',
          value: '${service.fee.toInt()} RWF',
        ),
        _InfoItem(
          icon: Icons.history,
          label: 'Payment',
          value: service.paymentMethod == 'PAY_BEFORE' ? 'Pre-paid' : 'Post-paid',
        ),
        _InfoItem(
          icon: Icons.check_circle_outline,
          label: 'Status',
          value: service.isActive ? 'Active' : 'Inactive',
        ),
      ],
    );
  }

  Widget _buildProviderInfo(ProviderInfo? provider) {
    if (provider == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Provider Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.inputFill,
                backgroundImage: provider.avatarUrl != null 
                    ? CachedNetworkImageProvider(provider.avatarUrl!) 
                    : null,
                child: provider.avatarUrl == null 
                    ? const Icon(Icons.person, color: AppColors.secondary) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (provider.businessName != null)
                      Text(
                        provider.businessName!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.secondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.workingHours != null)
            _ProviderDetailItem(icon: Icons.access_time, label: 'Hours', value: provider.workingHours!),
          if (provider.phone != null)
            _ProviderDetailItem(icon: Icons.phone, label: 'Phone', value: provider.phone!),
        ],
      ),
    );
  }

  Widget _buildDescription(String? description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          description ?? 'No description provided for this service.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ServiceModel service) {
    return PrimaryButton(
      label: 'Book Appointment',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AppointmentFormSheet(preselectedServiceId: service.id),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'WALKING':
        return Icons.pets;
      case 'GROOMING':
        return Icons.content_cut;
      case 'TRAINING':
        return Icons.school;
      case 'VETERINARY':
        return Icons.medical_services;
      default:
        return Icons.miscellaneous_services;
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.secondary, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

class _ProviderDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProviderDetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
