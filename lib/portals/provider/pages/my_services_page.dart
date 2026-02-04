import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

final List<Map<String, dynamic>> _mockServices = [
  {'name': 'Pet Grooming', 'price': 25000, 'duration': '1 hour', 'active': true},
  {'name': 'Full Checkup', 'price': 35000, 'duration': '45 min', 'active': true},
  {'name': 'Vaccination', 'price': 15000, 'duration': '30 min', 'active': true},
  {'name': 'Pet Training', 'price': 50000, 'duration': '2 hours', 'active': false},
];

class MyServicesPage extends StatelessWidget {
  const MyServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          GradientHeader(
            title: 'My Services',
            subtitle: 'Manage your service offerings',
          ),
          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _mockServices.length,
              itemBuilder: (context, index) {
                final service = _mockServices[index];
                return _ServiceCard(service: service);
              },
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

  void _showAddServiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Create New Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const AppTextField(label: 'Service Name', hint: 'e.g: Pet Grooming', prefixIcon: Icons.design_services),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: AppTextField(label: 'Price (RWF)', hint: '25000', prefixIcon: Icons.monetization_on)),
                SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Duration', hint: '1 hour', prefixIcon: Icons.timer)),
              ],
            ),
            const SizedBox(height: 16),
            const AppTextField(label: 'Description', hint: 'Describe your service...', prefixIcon: Icons.description),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create Service', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final isActive = service['active'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? AppColors.secondary.withOpacity(0.15) : AppColors.inputFill,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.design_services, size: 28, color: isActive ? AppColors.secondary : AppColors.textMuted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${service['price']} RWF', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text('• ${service['duration']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (val) {},
            activeColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

