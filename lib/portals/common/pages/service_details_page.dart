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
          backgroundColor: const Color(0xFFF8FAFC), // Premium light gray
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
      height: 250, 
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36), 
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 50,
            left: 10,
            child: Container(
              margin: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                     border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(
                    _getIconForType(service.category?.name ?? ''),
                    
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  service.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.category?.name ?? service.paymentTypeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _StatCard(
            label: 'Price',
            value: '${service.basePrice.toInt()} ${service.currency}',
            icon: Icons.payments_outlined,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
            label: 'Payment',
            value: service.paymentTypeLabel,
            icon: Icons.history,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
            label: 'Status',
            value: service.isAvailable ? 'Active' : 'Inactive',
            icon: Icons.check_circle_outline,
            valueColor: service.isAvailable ? AppColors.success : AppColors.textSecondary,
        )),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF1F5F9),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: const Icon(Icons.business, color: AppColors.secondary, size: 20)
              ),
              const SizedBox(width: 12),
              const Text(
                'Provider Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.inputFill,
                backgroundImage: provider.avatarUrl != null 
                    ? CachedNetworkImageProvider(resolveImageUrl(provider.avatarUrl!)) 
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    if (provider.title != null)
                      Text(
                        provider.title!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(
                       color: const Color(0xFF64748B).withValues(alpha: 0.08),
                       blurRadius: 4,
                       offset: const Offset(0, 2),
                     ),
                   ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.secondary, size: 22),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          
          if (provider.workingHours != null || provider.phone != null) ...[
             const SizedBox(height: 20),
             const Divider(height: 1, color: Color(0xFFE2E8F0)),
             const SizedBox(height: 16),
             if (provider.workingHours != null)
              _ProviderDetailItem(icon: Icons.access_time, label: 'Hours', value: provider.workingHours!),
             if (provider.phone != null)
               _ProviderDetailItem(icon: Icons.phone, label: 'Phone', value: provider.phone!),
          ]
        ],
      ),
    );
  }

  Widget _buildDescription(String? description) {
    return Container(
       width: double.infinity,
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
               color: const Color(0xFF64748B).withValues(alpha: 0.08),
               blurRadius: 16,
               offset: const Offset(0, 4),
             ),
           ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Text(
             'Service Description',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
           ),
           const SizedBox(height: 12),
           Text(
             description ?? 'No description provided for this service.',
             style: const TextStyle(color: Color(0xFF475569), height: 1.6, fontSize: 15),
           ),
         ],
       ),
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

  IconData _getIconForType(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('walk')) return Icons.pets;
    if (lower.contains('groom')) return Icons.content_cut;
    if (lower.contains('train')) return Icons.school;
    if (lower.contains('vet') || lower.contains('medical')) return Icons.medical_services;
    if (lower.contains('sit') || lower.contains('daycare')) return Icons.home_outlined;
    return Icons.design_services;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
             color: const Color(0xFF64748B).withValues(alpha: 0.08),
             blurRadius: 16,
             offset: const Offset(0, 4),
           ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? const Color(0xFF1E293B)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
