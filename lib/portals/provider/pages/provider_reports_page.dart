import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/appointment_providers.dart';

class ProviderReportsPage extends ConsumerStatefulWidget {
  const ProviderReportsPage({super.key});

  @override
  ConsumerState<ProviderReportsPage> createState() => _ProviderReportsPageState();
}

class _ProviderReportsPageState extends ConsumerState<ProviderReportsPage> {
  String _selectedRange = 'This Month';

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(providerAppointmentsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: 'Reports & Earnings',
            subtitle: 'Track your performance',
          ),
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (paginated) {
                final appointments = paginated.data;
                final completed = appointments.where((a) => a.status == 'COMPLETED').toList();
                
                // Calculate total earnings (mock calculation as ServiceModel might be null or fee might be missing)
                // Assuming service fee is available in AppointmentModel -> ServiceModel
                double totalEarnings = 0;
                for (var apt in completed) {
                   // If service is embedded
                   if (apt.service != null) {
                     totalEarnings += apt.service!.basePrice;
                   }
                }

                // Filter based on range (Mock for now)
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Range Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.3)),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedRange,
                              underline: const SizedBox(),
                              isDense: true,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              items: ['This Week', 'This Month', 'This Year'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) setState(() => _selectedRange = newValue);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total Earnings',
                              value: NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0).format(totalEarnings),
                              icon: Icons.monetization_on,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Completed Jobs',
                              value: '${completed.length}',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Transactions (Mock)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Earnings',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (completed.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No completed appointments yet.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: completed.take(10).length,
                          itemBuilder: (context, index) {
                            final apt = completed[index];
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
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.attach_money, color: AppColors.success),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          apt.service?.name ?? 'Service',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          DateFormat('MMM d, yyyy').format(apt.scheduledAt),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+${NumberFormat.decimalPattern().format(apt.service?.basePrice ?? 0)} RWF',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                ],
                              ),
                            );
                          },
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
