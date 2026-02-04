import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

final List<Map<String, dynamic>> _mockPets = [
  {'name': 'Tessy', 'species': 'Dog', 'breed': 'German Shepherd', 'age': '3 months', 'gender': 'Male', 'petCode': 'PET-2024-RW-001234', 'vaccinated': true},
  {'name': 'Whiskers', 'species': 'Cat', 'breed': 'Persian Cat', 'age': '6 months', 'gender': 'Female', 'petCode': 'PET-2024-RW-001235', 'vaccinated': false},
  {'name': 'Max', 'species': 'Dog', 'breed': 'Labrador', 'age': '2 years', 'gender': 'Male', 'petCode': 'PET-2024-RW-001236', 'vaccinated': true},
];

class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  State<MyPetsPage> createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Pets', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    _buildViewToggle(),
                  ],
                ),
                const SizedBox(height: 16),
                // Search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.white70),
                      SizedBox(width: 12),
                      Expanded(child: Text('Search pets...', style: TextStyle(color: Colors.white70))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isGridView ? _buildGridView() : _buildSliderView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPetSheet(context),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Pet', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isGridView = false),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: !_isGridView ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.view_carousel, size: 20, color: !_isGridView ? AppColors.secondary : Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _isGridView = true),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isGridView ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.grid_view, size: 20, color: _isGridView ? AppColors.secondary : Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderView() {
    return PageView.builder(
      controller: PageController(viewportFraction: 0.85),
      itemCount: _mockPets.length,
      itemBuilder: (context, index) => _PetDetailCard(pet: _mockPets[index]),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _mockPets.length,
      itemBuilder: (context, index) => _PetGridCard(pet: _mockPets[index]),
    );
  }

  void _showAddPetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Register New Pet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const AppTextField(label: 'Pet Name *', hint: 'e.g: Buddy', prefixIcon: Icons.pets),
              const SizedBox(height: 16),
              const AppTextField(label: 'Species *', hint: 'Select species', prefixIcon: Icons.category),
              const SizedBox(height: 16),
              const AppTextField(label: 'Breed', hint: 'e.g: German Shepherd', prefixIcon: Icons.pets),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: AppTextField(label: 'Age', hint: 'Years', prefixIcon: Icons.cake)),
                  SizedBox(width: 12),
                  Expanded(child: AppTextField(label: 'Weight (kg)', hint: 'kg', prefixIcon: Icons.monitor_weight)),
                ],
              ),
              const SizedBox(height: 16),
              const AppTextField(label: 'Address', hint: 'Location/District', prefixIcon: Icons.location_on),
              const SizedBox(height: 16),
              const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputFill, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 40, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text('Tap to upload', style: TextStyle(color: AppColors.textMuted)),
                  ],
                )),
              ),
              const SizedBox(height: 16),
              const Text('Gallery Photos', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) => Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_photo_alternate, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Vaccination Info', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.vaccines, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Add vaccination records', style: TextStyle(color: AppColors.textSecondary)),
                    Spacer(),
                    Icon(Icons.add, color: AppColors.secondary),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Parent Information (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const AppTextField(label: 'Father Pet Code', hint: 'PET-2024-RW-XXXXXX'),
              const SizedBox(height: 12),
              const AppTextField(label: 'Mother Pet Code', hint: 'PET-2024-RW-XXXXXX'),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Register Pet', onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetDetailCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  const _PetDetailCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.pets, size: 80, color: AppColors.secondary)),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: StatusBadge(label: pet['vaccinated'] == true ? 'Vaccinated' : 'Not Vaccinated', isPositive: pet['vaccinated'] == true),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pet['name'] as String, style: AppTypography.h2),
                      Icon(pet['gender'] == 'Male' ? Icons.male : Icons.female, color: pet['gender'] == 'Male' ? AppColors.secondary : Colors.pink),
                    ],
                  ),
                  Text(pet['breed'] as String, style: AppTypography.bodySmall),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FeatureChip(icon: Icons.cake, label: pet['age'] as String),
                      FeatureChip(icon: Icons.pets, label: pet['species'] as String),
                      FeatureChip(icon: Icons.qr_code, label: pet['petCode'] as String),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  const _PetGridCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.cardShadow),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: const Center(child: Icon(Icons.pets, size: 50, color: AppColors.secondary)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(pet['breed'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const Spacer(),
                  StatusBadge(label: pet['vaccinated'] == true ? 'Vaccinated' : 'Unvaccinated', isPositive: pet['vaccinated'] == true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

