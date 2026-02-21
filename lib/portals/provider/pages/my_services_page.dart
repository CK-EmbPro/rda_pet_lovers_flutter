import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/models/models.dart';
import '../widgets/service_form_sheet.dart';

final _servicesViewModeProvider = StateProvider<bool>((ref) => true); // true = grid

class MyServicesPage extends ConsumerWidget {
  const MyServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(myServicesProvider);
    final isCardView = ref.watch(_servicesViewModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 110,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              ),
              title: const Text(
                'My Services',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
                tooltip: 'Create Service',
                onPressed: () => ServiceFormSheet.show(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
        body: servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load services',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref.invalidate(myServicesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (services) => Column(
            children: [
              // ── Header bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${services.length} ${services.length == 1 ? "Service" : "Services"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        _ViewToggle(
                          icon: Icons.grid_view_rounded,
                          isSelected: isCardView,
                          onTap: () =>
                              ref.read(_servicesViewModeProvider.notifier).state = true,
                        ),
                        const SizedBox(width: 8),
                        _ViewToggle(
                          icon: Icons.view_list_rounded,
                          isSelected: !isCardView,
                          onTap: () =>
                              ref.read(_servicesViewModeProvider.notifier).state = false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: services.isEmpty
                    ? const EmptyState(
                        icon: Icons.design_services_outlined,
                        title: 'No Services Yet',
                        subtitle: 'Tap + above to create your first service',
                      )
                    : isCardView
                        ? _buildGrid(context, services)
                        : _buildList(context, services),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<ServiceModel> services) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: services.length,
      itemBuilder: (_, i) => _ServiceCard(service: services[i]),
    );
  }

  Widget _buildList(BuildContext context, List<ServiceModel> services) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (_, i) => _ServiceListTile(service: services[i]),
    );
  }

  static void showEdit(BuildContext context, ServiceModel service) {
    ServiceFormSheet.show(context, service: service);
  }

  // Keep backward-compatible alias
  static void showEditServiceSheet(BuildContext context, ServiceModel service) {
    ServiceFormSheet.show(context, service: service);
  }
}

// ─── View Toggle ─────────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggle({
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
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

// ─── Service Card (Grid) ──────────────────────────────────────────────────────

class _ServiceCard extends ConsumerWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: status + 3-dot menu ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AvailabilityBadge(isAvailable: service.isAvailable),
              _ServicePopupMenu(
                service: service,
                onDelete: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          const Spacer(),
          // ── Service icon ────────────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.design_services, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(height: 10),
          // ── Name ────────────────────────────────────────────────────
          Text(
            service.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // ── Category ────────────────────────────────────────────────
          if (service.category != null) ...[
            Text(
              service.category!.name,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          // ── Price ───────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 13, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                '${service.basePrice.toInt()} ${service.currency}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ── Payment type ─────────────────────────────────────────────
          Text(
            service.paymentTypeLabel,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          // ── Duration ─────────────────────────────────────────────────
          if (service.durationMinutes != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text(
                  service.durationLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    _showDeleteDialog(context, ref, service);
  }
}

// ─── Service List Tile ────────────────────────────────────────────────────────

class _ServiceListTile extends ConsumerWidget {
  final ServiceModel service;

  const _ServiceListTile({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: service.isAvailable
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.design_services,
              color: service.isAvailable ? AppColors.secondary : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // ── Details ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _AvailabilityBadge(isAvailable: service.isAvailable, compact: true),
                  ],
                ),
                const SizedBox(height: 4),
                if (service.category != null) ...[
                  Text(
                    service.category!.name,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    Text(
                      '${service.basePrice.toInt()} ${service.currency}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _Dot(),
                    const SizedBox(width: 8),
                    Text(
                      service.paymentTypeLabel,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    if (service.durationMinutes != null) ...[
                      const SizedBox(width: 8),
                      const _Dot(),
                      const SizedBox(width: 8),
                      Text(
                        service.durationLabel,
                        style:
                            const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // ── 3-dot menu ────────────────────────────────────────────────
          _ServicePopupMenu(
            service: service,
            onDelete: () => _showDeleteDialog(context, ref, service),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  final bool compact;

  const _AvailabilityBadge({required this.isAvailable, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.success : AppColors.error;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            size: 10,
            color: color,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              isAvailable ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 3-dot popup menu used in both card and list views.
/// Styled to match the My Pets page action menu pattern.
class _ServicePopupMenu extends ConsumerWidget {
  final ServiceModel service;
  final VoidCallback onDelete;

  const _ServicePopupMenu({required this.service, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) async {
          if (value == 'edit') {
            MyServicesPage.showEdit(context, service);
          } else if (value == 'toggle') {
            final result = await ref
                .read(serviceCrudProvider.notifier)
                .toggleAvailability(service.id);
            if (context.mounted) {
              if (result.success) {
                AppToast.success(context, result.message);
                ref.invalidate(myServicesProvider);
              } else {
                AppToast.error(context, result.message);
              }
            }
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: AppColors.textPrimary),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  service.isAvailable ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: service.isAvailable ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  service.isAvailable ? 'Deactivate' : 'Activate',
                  style: TextStyle(
                    color: service.isAvailable ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: AppColors.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delete dialog ────────────────────────────────────────────────────────────

void _showDeleteDialog(BuildContext context, WidgetRef ref, ServiceModel service) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Service'),
      content: Text('Are you sure you want to delete "${service.name}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final result =
                await ref.read(serviceCrudProvider.notifier).deleteService(service.id);
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
