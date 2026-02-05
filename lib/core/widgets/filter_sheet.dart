import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/providers/mock_data_provider.dart';

/// Filter Sheet for pets and services
class FilterSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onApply;
  
  const FilterSheet({super.key, this.onApply});

  static void show(BuildContext context, {Function(Map<String, dynamic>)? onApply}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(onApply: onApply),
    );
  }

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String? selectedBreed;
  String? selectedAge;
  String? selectedLocation;
  double priceMax = 100000;

  final List<String> ageRanges = ['1-2 yr', '1-3 month', '3-9 month', '1-5 yr'];

  @override
  Widget build(BuildContext context) {
    final breeds = ref.watch(breedsProvider);
    final locations = ref.watch(locationsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF21314C)),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Filter Page',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breed
                  _buildSectionHeader('Breed', onReset: () => setState(() => selectedBreed = null)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: breeds.map((breed) => _FilterChip(
                      label: breed.name,
                      isSelected: selectedBreed == breed.id,
                      onTap: () => setState(() => selectedBreed = breed.id),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Age
                  _buildSectionHeader('Age'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ageRanges.map((age) => _FilterChip(
                      label: age,
                      isSelected: selectedAge == age,
                      onTap: () => setState(() => selectedAge = age),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Location
                  _buildSectionHeader('Location'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: locations.map((loc) => _FilterChip(
                      label: loc.name,
                      isSelected: selectedLocation == loc.id,
                      onTap: () => setState(() => selectedLocation = loc.id),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Price
                  const Text('Price (frw)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Slider(
                    value: priceMax,
                    min: 0,
                    max: 500000,
                    divisions: 50,
                    activeColor: AppColors.secondary,
                    onChanged: (value) => setState(() => priceMax = value),
                  ),
                  Text('${priceMax.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} RWF',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply?.call({
                    'breed': selectedBreed,
                    'age': selectedAge,
                    'location': selectedLocation,
                    'maxPrice': priceMax,
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF21314C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Apply Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh, size: 16, color: AppColors.secondary),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF21314C) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
