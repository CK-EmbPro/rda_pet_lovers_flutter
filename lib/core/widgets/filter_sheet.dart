import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../data/providers/species_provider.dart';
import '../../data/providers/location_providers.dart';

/// Filter Sheet for pets and services — supports multi-select filters
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
  Set<String> selectedBreeds = {};
  Set<String> selectedAges = {};
  Set<String> selectedLocations = {};
  double priceMax = 100000;

  final List<String> ageRanges = ['< 1 year', '1 - 3 years', '3 - 7 years', '7+ years'];

  @override
  Widget build(BuildContext context) {
    final breedsAsync = ref.watch(allBreedsProvider);
    final locationsAsync = ref.watch(locationsProvider);

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
                const Spacer(),
                // Clear All button
                if (selectedBreeds.isNotEmpty || selectedAges.isNotEmpty || selectedLocations.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      selectedBreeds.clear();
                      selectedAges.clear();
                      selectedLocations.clear();
                      priceMax = 100000;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
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
                  // Breed (multi-select)
                  _buildSectionHeader(
                    'Breed',
                    count: selectedBreeds.length,
                    onReset: () => setState(() => selectedBreeds.clear()),
                  ),
                  const SizedBox(height: 12),
                  breedsAsync.when(
                    data: (breeds) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: breeds.map((breed) => _FilterChip(
                        key: ValueKey('breed_${breed.id}'),
                        label: breed.name,
                        isSelected: selectedBreeds.contains(breed.id),
                        onTap: () => setState(() {
                          final newSet = Set<String>.from(selectedBreeds);
                          if (newSet.contains(breed.id)) {
                            newSet.remove(breed.id);
                          } else {
                            newSet.add(breed.id);
                          }
                          selectedBreeds = newSet;
                        }),
                      )).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, r) => Text('Error loading breeds: $e'),
                  ),
                  const SizedBox(height: 24),

                  // Age (multi-select)
                  _buildSectionHeader(
                    'Age',
                    count: selectedAges.length,
                    onReset: () => setState(() => selectedAges.clear()),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ageRanges.map((age) => _FilterChip(
                      key: ValueKey('age_$age'),
                      label: age,
                      isSelected: selectedAges.contains(age),
                      onTap: () => setState(() {
                        final newSet = Set<String>.from(selectedAges);
                        if (newSet.contains(age)) {
                          newSet.remove(age);
                        } else {
                          newSet.add(age);
                        }
                        selectedAges = newSet;
                      }),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Location (multi-select)
                  _buildSectionHeader(
                    'Location',
                    count: selectedLocations.length,
                    onReset: () => setState(() => selectedLocations.clear()),
                  ),
                  const SizedBox(height: 12),
                  locationsAsync.when(
                    data: (locations) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: locations.map((loc) => _FilterChip(
                        key: ValueKey('loc_${loc.id}'),
                        label: loc.name,
                        isSelected: selectedLocations.contains(loc.id),
                        onTap: () => setState(() {
                          final newSet = Set<String>.from(selectedLocations);
                          if (newSet.contains(loc.id)) {
                            newSet.remove(loc.id);
                          } else {
                            newSet.add(loc.id);
                          }
                          selectedLocations = newSet;
                        }),
                      )).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, r) => Text('Error loading locations: $e'),
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

          // Active Filters Summary + Apply Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Active filter count
                if (_totalFilters > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '$_totalFilters filter${_totalFilters > 1 ? 's' : ''} active',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply?.call({
                        'breeds': selectedBreeds.toList(),
                        'ages': selectedAges.toList(),
                        'locations': selectedLocations.toList(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  int get _totalFilters => selectedBreeds.length + selectedAges.length + selectedLocations.length;

  Widget _buildSectionHeader(String title, {int count = 0, VoidCallback? onReset}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onReset != null && count > 0)
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

  const _FilterChip({super.key, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF21314C) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: const Color(0xFF21314C), width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
