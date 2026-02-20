import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/pet_providers.dart';
import '../../../data/providers/pet_listing_providers.dart';
import '../../../data/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';

class PetDetailsPage extends ConsumerStatefulWidget {
  final String petId;
  const PetDetailsPage({super.key, required this.petId});

  @override
  ConsumerState<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends ConsumerState<PetDetailsPage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Marketplace/Public view
    final petAsync = ref.watch(petDetailProvider(widget.petId));
    final cart = ref.watch(cartProvider);
    final isInCart = cart.any((i) => i.id == widget.petId && i.type == 'PET');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background
      body: petAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (pet) {
          final isSold = pet.sellingStatus == 'SOLD';
          final isOwner = pet.owner?.id == ref.read(currentUserProvider)?.id;
          final user = ref.watch(currentUserProvider);
          
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // App Bar with Image Slider
                    SliverAppBar(
                      expandedHeight: 400,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      actions: [
                        if (!pet.isForDonation)
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                                color: isInCart ? AppColors.secondary : Colors.black,
                                size: 20,
                              ),
                              onPressed: () {
                                final portalRoute = AppRouter.getPortalRoute(user?.primaryRole ?? 'user');
                                context.go('$portalRoute?tab=cart');
                              },
                            ),
                          ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildImageSlider(pet),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        transform: Matrix4.translationValues(0, -24, 0), // Visual overlap without negative margin
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Name, Price, Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pet.name,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E293B),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              pet.location?.name ?? 'Kigali, Rwanda',
                                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (pet.price != null && pet.price! > 0)
                                      Text(
                                        '${pet.price!.toInt()} RWF',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('Adoption', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSold ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isSold ? 'Sold' : 'Available',
                                        style: TextStyle(
                                          color: isSold ? Colors.red : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Stats Grid
                            Row(
                              children: [
                                Expanded(child: _buildStatCard('Age', '${pet.ageYears ?? 0} yrs', Icons.cake)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard('Gender', pet.gender.toUpperCase(), pet.gender == 'MALE' ? Icons.male : Icons.female)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard('Weight', '${pet.weightKg ?? 0} kg', Icons.monitor_weight)),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Listing Status Section (For Owner)
                            if (isOwner) ...[
                              _buildListingStatusBanner(pet),
                              const SizedBox(height: 32),
                            ],

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
                                   const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                   const SizedBox(height: 12),
                                   Text(
                                     pet.description ?? 'No description available for this pet.',
                                     style: const TextStyle(color: Color(0xFF475569), height: 1.6, fontSize: 15),
                                   ),
                                 ],
                               ),
                             ),
                            const SizedBox(height: 32),
                            
                            // Health & Vaccination Section (NEW)
                            if ((pet.healthSummary != null && pet.healthSummary!.isNotEmpty) || (pet.vaccinations != null && pet.vaccinations!.isNotEmpty))
                              Container(
                                 padding: const EdgeInsets.all(20),
                                 margin: const EdgeInsets.only(bottom: 32), // Separator
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
                        
                                     // Health Description
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
                                     ],
                                   ],
                                 ),
                              ),

                            // Ancestry Section (NEW)
                            if (pet.metadata != null && pet.metadata!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                margin: const EdgeInsets.only(bottom: 32),
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
                                           width: (MediaQuery.of(context).size.width - 96) / 2, // 2 cols depending on padding
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

                            // Owner / Seller Info
                            if (pet.owner != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16), // Rounded
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [ // Added shadow
                                   BoxShadow(
                                     color: const Color(0xFF64748B).withValues(alpha: 0.08),
                                     blurRadius: 16,
                                     offset: const Offset(0, 4),
                                   ),
                                 ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: pet.owner?.avatarUrl != null ? CachedNetworkImageProvider(resolveImageUrl(pet.owner!.avatarUrl!)) : null,
                                      child: pet.owner?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pet.owner!.fullName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                          ),
                                          const Text(
                                            'Owner / Seller',
                                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.message_outlined, color: AppColors.secondary),
                                      onPressed: () {
                                        AppToast.info(context, 'Chat feature coming soon 💬');
                                      },

                                    ),
                                  ],
                                ),
                              ),
                             const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Action Bar
              if (!isSold && !isOwner)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: pet.isForDonation
                      // ── Adoption: single "Adopt Now" button ──
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final shouldAdopt = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Adoption'),
                                  content: Text('Are you sure you want to adopt ${pet.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Adopt', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldAdopt != true) return;

                              try {
                                AppToast.info(context, 'Processing adoption...');
                                
                                if (pet.donationListingId == null) {
                                   AppToast.error(context, 'No active adoption listing found for this pet.');
                                   return;
                                }
                                
                                await ref.read(petListingServiceProvider).adopt(pet.donationListingId!);
                                
                                if (context.mounted) {
                                  // Invalidate listing caches immediately
                                  ref.invalidate(forAdoptionListingsProvider);
                                  ref.invalidate(allPetsProvider);

                                  // Show congratulations dialog explaining re-login
                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: const Row(
                                        children: [
                                          Text('🎉 ', style: TextStyle(fontSize: 28)),
                                          SizedBox(width: 4),
                                          Expanded(child: Text('Adoption Successful!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                      content: Text(
                                        '${pet.name} is now yours! 🐾\n\n'
                                        'Your account has been upgraded to Pet Owner. '
                                        'Please log in again to access your new Pet Owner features.',
                                        style: const TextStyle(height: 1.5),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF21314C),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text('Log In Now'),
                                        ),
                                      ],
                                    ),
                                  );

                                  // Force logout and redirect to login
                                  if (context.mounted) {
                                    await ref.read(authStateProvider.notifier).logout();
                                    if (context.mounted) context.go('/login');
                                  }
                                }

                              } catch (e) {
                                if (context.mounted) {
                                  AppToast.error(context, 'Adoption failed. Please try again.');
                                }
                              }
                            },
                            icon: const Icon(Icons.volunteer_activism, color: Colors.white),
                            label: const Text('Adopt Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF21314C),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        )
                      // ── For Sale: "Add to Cart" + "Buy Now" ──
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isInCart
                                    ? () => ref.read(cartProvider.notifier).removeItem(widget.petId, 'PET')
                                    : () => ref.read(cartProvider.notifier).addPet(pet),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: isInCart ? Colors.red : const Color(0xFF21314C)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Text(
                                  isInCart ? 'Remove' : 'Add to Cart',
                                  style: TextStyle(
                                    color: isInCart ? Colors.red : const Color(0xFF21314C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                   if (!isInCart) {
                                     ref.read(cartProvider.notifier).addPet(pet);
                                  }
                                  final portalRoute = AppRouter.getPortalRoute(user?.primaryRole ?? 'user');
                                  context.go('$portalRoute?tab=cart');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF21314C),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text('Buy Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageSlider(PetModel pet) {
     if (pet.images.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.pets, size: 64, color: Colors.grey)),
      );
    }
    
    return Stack(
      children: [
        PageView.builder(
          itemCount: pet.images.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: resolveImageUrl(pet.images[index]),
                  fit: BoxFit.fill,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, _) => const Icon(Icons.error),
                ),
                // Gradient Overlay for readability (especially on first image with title overlay if we had one there)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Pagination Dots
        Positioned(
          bottom: 40, 
          left: 0, 
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pet.images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentImageIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentImageIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Changed to white
        borderRadius: BorderRadius.circular(16),
        // Removed border, added shadow
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
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildListingStatusBanner(PetModel pet) {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    if (pet.isForSale) {
      title = 'Listed for Sale';
      subtitle = 'Available for purchase at ${pet.price?.toInt() ?? 0} RWF';
      icon = Icons.sell_outlined;
      color = AppColors.secondary;
    } else if (pet.isForDonation) {
      title = 'Listed for Donation';
      subtitle = 'Available for free adoption';
      icon = Icons.volunteer_activism_outlined;
      color = Colors.green;
    } else {
      title = 'Private Listing';
      subtitle = 'Not visible in the marketplace';
      icon = Icons.lock_outline;
      color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
