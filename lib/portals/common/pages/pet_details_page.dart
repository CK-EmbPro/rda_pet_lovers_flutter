import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/pet_providers.dart';
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
    final isInCart = cart.items.any((i) => i.productId == widget.petId && i.type == 'PET');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background
      body: petAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (pet) {
          final isSold = pet.isSold;
          final isOwner = pet.owner?.id == ref.read(authProvider).user?.id;
          final user = ref.watch(authProvider).user;
          
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
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
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
                              context.push('$portalRoute/cart');
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
                        margin: const EdgeInsets.only(top: -24), // Overlap slider
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
                                        color: isSold ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
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

                            // About Section
                            const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 12),
                            Text(
                              pet.description ?? 'No description available for this pet.',
                              style: const TextStyle(color: Color(0xFF475569), height: 1.6, fontSize: 15),
                            ),
                            const SizedBox(height: 32),

                            // Owner / Seller Info
                            if (pet.owner != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: pet.owner?.profileImage != null ? CachedNetworkImageProvider(pet.owner!.profileImage!) : null,
                                      child: pet.owner?.profileImage == null ? const Icon(Icons.person, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pet.owner!.name,
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
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat feature coming soon')));
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isInCart
                              ? () => ref.read(cartProvider.notifier).removeItem(widget.petId)
                              : () => ref.read(cartProvider.notifier).addItem(
                                    CartItem(
                                      productId: widget.petId,
                                      name: pet.name,
                                      price: pet.price ?? 0,
                                      image: pet.images.isNotEmpty ? pet.images.first : null,
                                      type: 'PET',
                                    ),
                                  ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: isInCart ? Colors.red : AppColors.secondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            isInCart ? 'Remove' : 'Add to Cart',
                            style: TextStyle(
                              color: isInCart ? Colors.red : AppColors.secondary,
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
                               ref.read(cartProvider.notifier).addItem(
                                    CartItem(
                                      productId: widget.petId,
                                      name: pet.name,
                                      price: pet.price ?? 0,
                                      image: pet.images.isNotEmpty ? pet.images.first : null,
                                      type: 'PET',
                                    ),
                                  );
                            }
                            final portalRoute = AppRouter.getPortalRoute(user?.primaryRole ?? 'user');
                            context.push('$portalRoute/cart');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
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
            return CachedNetworkImage(
              imageUrl: pet.images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, _) => const Icon(Icons.error),
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
                  color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
}
