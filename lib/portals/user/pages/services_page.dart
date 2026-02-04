import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/mock_data_provider.dart';
import '../../../data/models/models.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'VETERINARY', 'GROOMING', 'TRAINING', 'WALKING'];

  String _getCategoryLabel(String type) {
    switch (type) {
      case 'VETERINARY': return 'Veterinary';
      case 'GROOMING': return 'Grooming';
      case 'TRAINING': return 'Training';
      case 'WALKING': return 'Walking';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesByTypeProvider(_selectedCategory == 'All' ? null : _selectedCategory));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          GradientHeader(
            title: 'Services',
            subtitle: 'Find the best care for your pet',
            trailing: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {},
            ),
          ),

          // Category Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.inputFill,
                        ),
                      ),
                      child: Text(
                        cat == 'All' ? 'All' : _getCategoryLabel(cat),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Services List
          Expanded(
            child: services.isEmpty
                ? const EmptyState(
                    icon: Icons.miscellaneous_services,
                    title: 'No Services Found',
                    subtitle: 'No services available in this category',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _ServiceCard(service: service);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to service details/booking
        _showBookingSheet(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Provider Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.inputFill,
              backgroundImage: service.provider?.avatarUrl != null
                  ? CachedNetworkImageProvider(service.provider!.avatarUrl!)
                  : null,
              child: service.provider?.avatarUrl == null
                  ? const Icon(Icons.person, size: 28, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: 16),
            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.provider?.fullName ?? 'Provider',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(
                        label: service.displayServiceType,
                        isPositive: true,
                      ),
                      const Spacer(),
                      Text(
                        'RWF ${service.fee.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: AppColors.inputFill,
                          backgroundImage: service.provider?.avatarUrl != null
                              ? CachedNetworkImageProvider(service.provider!.avatarUrl!)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.provider?.fullName ?? 'Provider',
                                style: AppTypography.h3,
                              ),
                              Text(
                                service.provider?.specialty ?? service.displayServiceType,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Service Details
                    Text('Service', style: AppTypography.caption),
                    const SizedBox(height: 4),
                    Text(service.name, style: AppTypography.h3),
                    const SizedBox(height: 8),
                    Text(
                      service.description ?? 'Professional pet care service.',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    // Working Hours
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          service.provider?.workingHours ?? '8:00 am - 6:00 pm',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Fee & Book
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price', style: TextStyle(color: AppColors.textMuted)),
                            Text(
                              'RWF ${service.fee.toStringAsFixed(0)}',
                              style: AppTypography.h2.copyWith(color: AppColors.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Book Now',
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking feature coming soon!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
