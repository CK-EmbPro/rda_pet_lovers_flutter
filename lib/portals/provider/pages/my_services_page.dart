import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/models/models.dart';
import '../widgets/service_form_sheet.dart';

// Provider for services listing mode
final servicesViewModeProvider = StateProvider<bool>((ref) => true); // true = card, false = list

class MyServicesPage extends ConsumerWidget {
  const MyServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(myServicesProvider);
    final isCardView = ref.watch(servicesViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
              ),
              title: const Text('My Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                onPressed: () => _showAddServiceSheet(context),
              ),
            ],
          ),
        ],
        body: servicesAsync.when(
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load services', style: AppTypography.body),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(myServicesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (services) => Column(
            children: [
              // View Toggle Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${services.length} Services',
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
                          onTap: () => ref.read(servicesViewModeProvider.notifier).state = true,
                        ),
                        const SizedBox(width: 8),
                        _ViewToggleButton(
                          icon: Icons.view_list_rounded,
                          isSelected: !isCardView,
                          onTap: () => ref.read(servicesViewModeProvider.notifier).state = false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Services List
              Expanded(
                child: services.isEmpty
                    ? const EmptyState(
                        icon: Icons.design_services,
                        title: 'No Services',
                        subtitle: 'Create your first service to see it here!',
                      )
                    : isCardView
                        ? _buildCardView(context, services)
                        : _buildListView(context, services),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardView(BuildContext context, List<ServiceModel> services) {
    return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
            return _ServiceCardView(service: services[index]);
        },
    );
  }

  Widget _buildListView(BuildContext context, List<ServiceModel> services) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _ServiceListView(service: services[index]);
      },
    );
  }

  void _showAddServiceSheet(BuildContext context) {
    ServiceFormSheet.show(context);
  }

  static void showEditServiceSheet(BuildContext context, ServiceModel service) {
    ServiceFormSheet.show(context, service: service);
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

// Service Card View (Grid)
class _ServiceCardView extends ConsumerWidget {
  final ServiceModel service;

  const _ServiceCardView({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: service.isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      service.isActive ? Icons.check_circle : Icons.cancel,
                      size: 12,
                      color: service.isActive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        color: service.isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation(context, ref);
                  } else if (value == 'edit') {
                    MyServicesPage.showEditServiceSheet(context, service);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppColors.error, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Service Name
          Text(
            service.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Details
          Row(
            children: [
               Icon(Icons.payments_outlined, size: 14, color: AppColors.textSecondary),
               const SizedBox(width: 4),
               Text(
                 '${service.fee.toInt()} RWF',
                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
               ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
               Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
               const SizedBox(width: 4),
               Expanded(
                 child: Text(
                   service.paymentMethod == 'PAY_BEFORE' ? 'Pay Before' : 'Pay After',
                   style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
            ],
          ),
          const SizedBox(height: 12),
          // Edit Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => MyServicesPage.showEditServiceSheet(context, service),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Edit Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref.read(serviceCrudProvider.notifier).deleteService(service.id);
              if (context.mounted) {
                if (result.success) {
                  AppToast.success(context, result.message);
                  ref.invalidate(myServicesProvider);
                } else {
                  AppToast.error(context, result.message);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Service List View
class _ServiceListView extends ConsumerWidget {
  final ServiceModel service;

  const _ServiceListView({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: service.isActive ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.design_services,
              color: service.isActive ? AppColors.secondary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                   children: [
                     Expanded(
                       child: Text(
                         service.name,
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     if (!service.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text('INACTIVE', style: TextStyle(fontSize: 9, color: AppColors.error, fontWeight: FontWeight.bold)),
                        ),
                   ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${service.fee.toInt()} RWF',
                      style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      service.paymentMethod == 'PAY_BEFORE' ? 'Pay Before' : 'Pay After',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => MyServicesPage.showEditServiceSheet(context, service),
                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                iconSize: 20,
                style: IconButton.styleFrom(backgroundColor: AppColors.inputFill),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showDeleteConfirmation(context, ref),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                iconSize: 20,
                style: IconButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref.read(serviceCrudProvider.notifier).deleteService(service.id);
              if (context.mounted) {
                if (result.success) {
                  AppToast.success(context, result.message);
                  ref.invalidate(myServicesProvider);
                } else {
                  AppToast.error(context, result.message);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
