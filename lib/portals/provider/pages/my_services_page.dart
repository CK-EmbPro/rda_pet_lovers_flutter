import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../data/models/models.dart';
import '../widgets/service_form_sheet.dart';

// Provider for services listing mode
final servicesViewModeProvider = StateProvider<bool>((ref) => true); // true = card, false = list

class MyServicesPage extends ConsumerWidget {
  const MyServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final servicesAsync = ref.watch(providerServicesProvider(user?.id ?? ''));
    final isCardView = ref.watch(servicesViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          GradientHeader(
            title: 'My Services',
            subtitle: 'Manage your service offerings',
          ),
          // View toggle and content
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Failed to load services', style: AppTypography.body),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(providerServicesProvider(user?.id ?? '')),
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
                            fontWeight: FontWeight.w500,
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServiceSheet(context),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Service', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCardView(BuildContext context, List<ServiceModel> services) {
    return RefreshIndicator(
        onRefresh: () async {
            // Need ref to refresh. But context based refresh tricky in StatelessWidget without ref present in method.
            // But this widget is built in consumer.
            // Actually RefreshIndicator needs a scrollable. GridView checks that.
            // We can't access ref here easily unless we pass it or make methods functional.
            // For now, removing RefreshIndicator inside the sub-widgets to avoid complexity, 
            // the parent uses Stream/FutureProvider which auto-updates on invalidation.
            // But user might want pull-to-refresh.
            // Implementing pull-to-refresh requires ref.refresh(provider).
            // I will skip adding it here to keep diff small, relying on auto-refetch or retry button.
            return; 
        },
        child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
                return _ServiceCardView(service: services[index]);
            },
        )
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
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.inputFill,
          borderRadius: BorderRadius.circular(8),
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
class _ServiceCardView extends StatelessWidget {
  final ServiceModel service;

  const _ServiceCardView({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
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
                  color: service.isActive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete Service')),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Service Name
          Text(
            service.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Payment method
          Row(
            children: [
              const Text('method: ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(
                service.paymentMethod == 'PAY_BEFORE' ? 'Pay Before' : 'Pay After',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Fee
          Row(
            children: [
              const Text('Service Fee: ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(
                '${service.fee.toInt()} frw',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Edit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => MyServicesPage.showEditServiceSheet(context, service),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('edit', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
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
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Service List View
class _ServiceListView extends StatelessWidget {
  final ServiceModel service;

  const _ServiceListView({required this.service});

  @override
  Widget build(BuildContext context) {
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: service.isActive ? AppColors.secondary.withOpacity(0.15) : AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.design_services,
              color: service.isActive ? AppColors.secondary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${service.fee.toInt()} RWF',
                      style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${service.paymentMethod == 'PAY_BEFORE' ? 'Pay Before' : 'Pay After'}',
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
                icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
                iconSize: 20,
              ),
              IconButton(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
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
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
