import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/auth_providers.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'key': 'All', 'label': 'All', 'icon': '🐾'},
    {'key': 'VETERINARY', 'label': 'Veterinary', 'icon': '🩺'},
    {'key': 'GROOMING', 'label': 'Groom', 'icon': '✂️'},
    {'key': 'TRAINING', 'label': 'Training', 'icon': '🎓'},
    {'key': 'WALKING', 'label': 'Walk', 'icon': '🚶'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce can be added here if needed, for now just setState
    setState(() {
      _searchTerm = _searchController.text;
    });
  }

  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(allServicesProvider(ServiceQueryParams(
      serviceType: _selectedCategory == 'All' ? null : _selectedCategory,
      search: _searchTerm.isEmpty ? null : _searchTerm,
    )));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header matching design
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pet Health',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find the best care for your pet',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search services...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category Filter Chips
          Container(
            height: 60, // Sligthly increased height
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.none, // Allow shadows
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['key']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF21314C) : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: isSelected ? [] : AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Text(cat['icon'], style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            cat['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Services List
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load services', style: AppTypography.body),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(allServicesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (paginatedResult) {
                final services = paginatedResult.data;
                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.miscellaneous_services, size: 60, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        const Text('No Services Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('No services available in this category', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ProviderCard(service: service);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  final ServiceModel service;
  const _ProviderCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/service-details/${service.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Availability Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                  SizedBox(width: 4),
                  Text(
                    'Available',
                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Provider Info Row
            Row(
              children: [
                // Provider Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.inputFill,
                  backgroundImage: service.provider?.avatarUrl != null
                      ? CachedNetworkImageProvider(resolveImageUrl(service.provider!.avatarUrl!))
                      : null,
                  child: service.provider?.avatarUrl == null
                      ? const Icon(Icons.person, size: 28, color: AppColors.textSecondary)
                      : null,
                ),
                const SizedBox(width: 12),
                // Provider Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.provider?.fullName ?? 'Dr. Provider',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        service.provider?.specialty ?? service.displayServiceType,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            service.provider?.workingHours ?? '8:00 am - 6:00 pm',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Service Info and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Text(
                      service.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '${service.fee.toInt()} RWF',
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
  
            // Schedule Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final user = ref.read(currentUserProvider);
                  if (user == null || user.primaryRole == 'user') {
                    _showGuestRestriction(context, 'schedule an appointment');
                  } else {
                    AppointmentFormSheet.show(context, serviceId: service.id, providerId: service.providerId);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21314C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Schedule Appointment',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuestRestriction(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Pet Ownership Required', textAlign: TextAlign.center),
        content: Text(
          'To perform this action, you must own a pet by either creating it, buying it, or adopting it.',
          textAlign: TextAlign.center,
        ),
        actions: [], // No buttons as requested
      ),
    );
  }
}
