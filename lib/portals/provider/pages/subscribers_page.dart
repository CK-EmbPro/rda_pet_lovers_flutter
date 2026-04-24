import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/subscription_providers.dart';

/// Provider portal page — shows all subscribers and allows session deduction.
class SubscribersPage extends ConsumerStatefulWidget {
  const SubscribersPage({super.key});

  @override
  ConsumerState<SubscribersPage> createState() => _SubscribersPageState();
}

class _SubscribersPageState extends ConsumerState<SubscribersPage> {
  int _filterIndex = 0;
  final _filters = ['All', 'Active', 'Expired', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(mySubscribersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilters(),
          Expanded(
            child: subsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('Failed to load subscribers',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(mySubscribersProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (subs) {
                final filtered = _filterIndex == 0
                    ? subs
                    : subs
                        .where((s) =>
                            s.status ==
                            _filters[_filterIndex].toUpperCase())
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_outlined,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _filterIndex == 0
                              ? 'No subscribers yet.'
                              : 'No ${_filters[_filterIndex].toLowerCase()} subscribers.',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                // Summary stats banner (active only)
                final active =
                    subs.where((s) => s.status == 'ACTIVE').length;

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(mySubscribersProvider),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          child: _StatBanner(
                              total: subs.length, active: active),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _SubscriberCard(sub: filtered[i]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Subscribers',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            _filters.length,
            (i) => GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _filterIndex == i
                      ? AppColors.primary
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    color: _filterIndex == i
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontWeight: _filterIndex == i
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBanner extends StatelessWidget {
  final int total;
  final int active;
  const _StatBanner({required this.total, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Total', value: total.toString()),
          Container(width: 1, height: 32, color: AppColors.border),
          _Stat(
              label: 'Active',
              value: active.toString(),
              valueColor: AppColors.success),
          Container(width: 1, height: 32, color: AppColors.border),
          _Stat(
              label: 'Inactive',
              value: (total - active).toString(),
              valueColor: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SubscriberCard extends ConsumerStatefulWidget {
  final ProviderSubscriptionModel sub;
  const _SubscriberCard({required this.sub});

  @override
  ConsumerState<_SubscriberCard> createState() => _SubscriberCardState();
}

class _SubscriberCardState extends ConsumerState<_SubscriberCard> {
  bool _using = false;

  Future<void> _useSession() async {
    setState(() => _using = true);
    final (updated, error) = await ref
        .read(subscriptionActionProvider.notifier)
        .useSession(widget.sub.id);
    if (!mounted) return;
    setState(() => _using = false);

    if (updated != null) {
      final remaining = updated.sessionsRemaining ?? 0;
      AppToast.success(
          context,
          remaining > 0
              ? 'Session used. $remaining session${remaining == 1 ? '' : 's'} remaining.'
              : 'Session used. Subscription exhausted.');
    } else {
      AppToast.error(context, error ?? 'Failed to use session.');
    }
  }

  Color get _statusColor {
    switch (widget.sub.status) {
      case 'ACTIVE':
        return widget.sub.isExpiringSoon
            ? AppColors.warning
            : AppColors.success;
      case 'EXPIRED':
        return AppColors.textMuted;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.sub;
    final customerName = sub.customer?.fullName ?? sub.subscriptionCode;
    final planName = sub.model?.name ?? 'Plan';
    final isSessionBased = sub.model?.isSessionBased ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar placeholder
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(customerName,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sub.isExpiringSoon ? 'Expiring Soon' : sub.statusLabel,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Days / sessions remaining
              Expanded(
                child: isSessionBased && sub.sessionsRemaining != null
                    ? _InfoChip(
                        icon: Icons.repeat_outlined,
                        text:
                            '${sub.sessionsRemaining} session${sub.sessionsRemaining! == 1 ? '' : 's'} left')
                    : _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        text: sub.isActive
                            ? '${sub.daysRemaining}d left'
                            : _formatDate(sub.endDate)),
              ),
              const SizedBox(width: 8),
              // Use Session button (only for active SESSION_BASED)
              if (sub.isActive && isSessionBased)
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: _using ||
                            (sub.sessionsRemaining != null &&
                                sub.sessionsRemaining! <= 0)
                        ? null
                        : _useSession,
                    icon: _using
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline,
                            size: 16),
                    label: const Text('Use Session',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
