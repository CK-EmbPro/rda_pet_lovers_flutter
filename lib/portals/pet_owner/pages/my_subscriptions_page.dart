import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/subscription_providers.dart';

class MySubscriptionsPage extends ConsumerStatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  ConsumerState<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends ConsumerState<MySubscriptionsPage> {
  int _filterIndex = 0;
  final _filters = ['All', 'Active', 'Expired', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(mySubscriptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilters(),
          Expanded(
            child: subsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('Failed to load subscriptions',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(mySubscriptionsProvider),
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
                            s.status == _filters[_filterIndex].toUpperCase())
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.subscriptions_outlined,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _filterIndex == 0
                              ? 'No subscriptions yet.\nBrowse provider plans to get started.'
                              : 'No ${_filters[_filterIndex].toLowerCase()} subscriptions.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(mySubscriptionsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) =>
                        _SubscriptionCard(sub: filtered[i]),
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
            'My Subscriptions',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _SubscriptionCard extends ConsumerStatefulWidget {
  final ProviderSubscriptionModel sub;
  const _SubscriptionCard({required this.sub});

  @override
  ConsumerState<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<_SubscriptionCard> {
  bool _cancelling = false;
  bool _toggling = false;

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

  Future<void> _cancel() async {
    final reason = await _showCancelDialog();
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    final ok = await ref
        .read(subscriptionActionProvider.notifier)
        .cancel(widget.sub.id, reason: reason.isEmpty ? null : reason);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (ok) {
      AppToast.success(context, 'Subscription cancelled.');
    } else {
      AppToast.error(context, 'Failed to cancel subscription.');
    }
  }

  Future<String?> _showCancelDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Subscription',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this subscription?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Plan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutoRenew() async {
    setState(() => _toggling = true);
    final ok = await ref
        .read(subscriptionActionProvider.notifier)
        .toggleAutoRenew(widget.sub.id);
    if (!mounted) return;
    setState(() => _toggling = false);
    if (!ok) AppToast.error(context, 'Failed to update auto-renew.');
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.sub;
    final planName = sub.model?.name ?? 'Subscription';
    final providerName =
        sub.provider?.fullName ?? sub.provider?.businessName ?? 'Provider';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    planName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub.isExpiringSoon ? 'Expiring Soon' : sub.statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Provider',
                    value: providerName),
                const SizedBox(height: 8),
                if (sub.model != null)
                  _InfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Price',
                      value:
                          '${sub.model!.price.toInt()} ${sub.model!.currency}'),
                if (sub.model?.isSessionBased == true &&
                    sub.sessionsRemaining != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.repeat_outlined,
                      label: 'Sessions left',
                      value: '${sub.sessionsRemaining}'),
                ],
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Expires',
                    value: sub.isActive
                        ? '${sub.daysRemaining} day${sub.daysRemaining == 1 ? '' : 's'} left'
                        : _formatDate(sub.endDate)),
                if (sub.isActive) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Auto-renew toggle
                      Row(
                        children: [
                          const Text('Auto-renew',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(width: 8),
                          _toggling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Switch(
                                  value: sub.autoRenew,
                                  onChanged: (_) => _toggleAutoRenew(),
                                  activeColor: AppColors.primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                        ],
                      ),
                      // Cancel button
                      _cancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton(
                              onPressed: _cancel,
                              child: const Text('Cancel Plan',
                                  style:
                                      TextStyle(color: AppColors.error)),
                            ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}
