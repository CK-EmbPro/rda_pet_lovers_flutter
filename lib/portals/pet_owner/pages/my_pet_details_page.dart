import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/appointment_form_sheet.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/providers/appointment_providers.dart';

class MyPetDetailsPage extends ConsumerStatefulWidget {
  final String petId;
  const MyPetDetailsPage({super.key, required this.petId});

  @override
  ConsumerState<MyPetDetailsPage> createState() => _MyPetDetailsPageState();
}

class _MyPetDetailsPageState extends ConsumerState<MyPetDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petDetailProvider(widget.petId));
    
    return petAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load pet details: $e')),
      ),
      data: (pet) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Header with Back Button and Tabs
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF21314C)),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: 56,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Light background
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: const Color(0xFF1E293B),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Profile'),
                        Tab(text: 'Appointments'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(pet),
                  _buildAppointmentsTab(pet),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(20),
          child: PrimaryButton(
            label: 'Schedule appointment',
            icon: Icons.north_east,
            onPressed: () => AppointmentFormSheet.show(context),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(PetModel pet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Slider
          _buildImageSlider(pet),
          const SizedBox(height: 24),

          // Quick Info Cards
          Row(
            children: [
              _OwnStatCard(icon: Icons.cake, label: '${pet.ageYears ?? 1} Years'),
              const SizedBox(width: 12),
              _OwnStatCard(icon: pet.gender == 'MALE' ? Icons.male : Icons.female, label: pet.gender.toUpperCase()),
              const SizedBox(width: 12),
              _OwnStatCard(icon: Icons.monitor_weight, label: '${pet.weightKg ?? 0} Kg'),
            ],
          ),
          const SizedBox(height: 24),

          // Health Status & Vaccinations
          Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(24),
               boxShadow: [
                 BoxShadow(
                   color: const Color(0xFF64748B).withValues(alpha: 0.08),
                   blurRadius: 16,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             child: Column(
               children: [
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                         color: const Color(0xFFE0F2FE), // Light Blue bg
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: const Icon(Icons.medical_services_outlined, color: AppColors.secondary, size: 20),
                     ),
                     const SizedBox(width: 14),
                     const Text('Health & Vaccines', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
                   ],
                 ),
                 const SizedBox(height: 20),

                 // Health Description (from Registration form)
                 if (pet.healthSummary != null && pet.healthSummary!.isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 20),
                     child: Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: const Color(0xFFF8FAFC),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: const Color(0xFFE2E8F0)),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text(
                             'Condition & Notes',
                             style: TextStyle(
                               fontSize: 13,
                               fontWeight: FontWeight.bold,
                               color: Color(0xFF64748B),
                               letterSpacing: 0.5,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             pet.healthSummary!,
                             style: const TextStyle(
                               fontSize: 14,
                               color: Color(0xFF334155),
                               height: 1.5,
                              ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 
                 if (pet.vaccinations != null && pet.vaccinations!.isNotEmpty) ...[
                   ...pet.vaccinations!.map((v) => Container(
                     margin: const EdgeInsets.only(bottom: 12),
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: const Color(0xFFF8FAFC),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: const Color(0xFFE2E8F0)),
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.check_circle, size: 20, color: AppColors.success),
                         const SizedBox(width: 12),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(v.vaccination?.name ?? 'Vaccination', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155))),
                             if (v.administeredAt != null)
                               Text(
                                 'Administered: ${v.administeredAt!.substring(0, 10)}', 
                                 style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)
                               ),
                           ],
                         ),
                       ],
                     ),
                   )),
                 ] else ...[
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: const Color(0xFFF8FAFC),
                       borderRadius: BorderRadius.circular(16),
                     ),
                     child: const Text('No vaccinations recorded yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 13), textAlign: TextAlign.center),
                   ),
                 ],
               ],
             ),
          ),
          const SizedBox(height: 24),

          // About Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(
                   color: const Color(0xFF64748B).withValues(alpha: 0.08),
                   blurRadius: 16,
                   offset: const Offset(0, 4),
                 ),
               ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('About Pet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Text(
                  pet.description ?? 'No description available for this pet.',
                  style: const TextStyle(color: Color(0xFF475569), height: 1.6, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ancestry Section
          if (pet.metadata != null && pet.metadata!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                 BoxShadow(
                   color: const Color(0xFF64748B).withValues(alpha: 0.08),
                   blurRadius: 16,
                   offset: const Offset(0, 4),
                 ),
               ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ancestry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: pet.metadata!.entries.map((e) {
                       // Format key: motherPetCode -> Mother
                       String label = e.key.replaceAll('PetCode', '');
                       label = label[0].toUpperCase() + label.substring(1);
                       return Container(
                         width: (MediaQuery.of(context).size.width - 96) / 2, // 2 cols
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: const Color(0xFFF8FAFC),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: const Color(0xFFE2E8F0)),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                             const SizedBox(height: 4),
                             Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary)),
                           ],
                         ),
                       );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImageSlider(PetModel pet) {
    if (pet.images.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: Icon(Icons.pets, size: 64, color: AppColors.secondary)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 320, // Increased height slightly
          child: PageView.builder(
            itemCount: pet.images.length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(pet.images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    if (index == 0) // Gradient Overlay for Profile Image
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4],
                          ),
                        ),
                      ),
                    
                    if (index == 0) // Overlay name on first image (profile)
                      Positioned(
                        top: 24,
                        left: 24,
                        child: Text(
                          pet.name.toUpperCase(), 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 32, 
                            fontWeight: FontWeight.w800, 
                            letterSpacing: 1.0,
                            shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Dots
        if (pet.images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pet.images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentImageIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentImageIndex == index ? AppColors.secondary : const Color(0xFFE2E8F0),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildAppointmentsTab(PetModel pet) {
     final appointmentsAsync = ref.watch(myAppointmentsProvider(null));

     return appointmentsAsync.when(
       loading: () => const Center(child: CircularProgressIndicator()),
       error: (e, _) => Center(child: Text('Error: $e')),
       data: (paginated) {
         final appointments = paginated.data.where((a) => a.petId == pet.id).toList();

         if (appointments.isEmpty) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                 const SizedBox(height: 16),
                 const Text('No appointments yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
               ],
             ),
           );
         }

         return ListView.builder(
           padding: const EdgeInsets.all(24),
           itemCount: appointments.length,
           itemBuilder: (context, index) {
             final apt = appointments[index];
             return Container(
               margin: const EdgeInsets.only(bottom: 20),
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(24),
                 boxShadow: [
                   BoxShadow(
                     color: const Color(0xFF64748B).withValues(alpha: 0.08),
                     blurRadius: 16,
                     offset: const Offset(0, 4),
                   ),
                 ],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(
                           color: const Color(0xFFF1F5F9),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: const Icon(Icons.calendar_month, size: 20, color: AppColors.secondary),
                       ),
                       const SizedBox(width: 14),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             '${apt.scheduledAt.day}/${apt.scheduledAt.month}/${apt.scheduledAt.year}',
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                           ),
                           const SizedBox(height: 2),
                           Text(
                             '${apt.scheduledAt.hour.toString().padLeft(2, '0')}:${apt.scheduledAt.minute.toString().padLeft(2, '0')}',
                             style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                           ),
                         ],
                       ),
                       const Spacer(),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: apt.status == 'CONFIRMED' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text(
                           apt.status, 
                           style: TextStyle(
                             fontSize: 12, 
                             fontWeight: FontWeight.bold,
                             color: apt.status == 'CONFIRMED' ? const Color(0xFF166534) : const Color(0xFF475569),
                           ),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   const Divider(height: 1, color: Color(0xFFE2E8F0)),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       const Icon(Icons.business, size: 16, color: Color(0xFF94A3B8)),
                       const SizedBox(width: 8),
                       Text(
                         'Provider: ${apt.provider?.businessName ?? "Unknown"}', 
                         style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                       ),
                     ],
                   ),
                 ],
               ),
             );
           },
         );
       }
     );
  }
}

class _OwnStatCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OwnStatCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.secondary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF21314C))),
          ],
        ),
      ),
    );
  }
}
