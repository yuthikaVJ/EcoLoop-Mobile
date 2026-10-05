import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../materials_marketplace/domain/entities/material_listing.dart';
import '../../../materials_marketplace/presentation/pages/material_details_page.dart';
import '../../../materials_marketplace/presentation/providers/material_listings_provider.dart';
import '../../../materials_marketplace/presentation/pages/add_material_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../sustainable_products/data/product_repository.dart';
import '../../../sustainable_products/domain/entities/product.dart';
import '../../../sustainable_products/presentation/pages/product_details_page.dart';
import '../../../sustainable_products/presentation/widgets/product_image_widget.dart';
import '../../../transactions_delivery/data/services/component4_api_service.dart';

/// The signed-in business's real activity (replaces the old placeholder stats).
class _HomeStats {
  final int completedDeals;
  final double sales;
  const _HomeStats(this.completedDeals, this.sales);
}

final _homeStatsProvider = FutureProvider.autoDispose<_HomeStats>((ref) async {
  final api = Component4ApiService();
  try {
    final transactions = await Future.wait([
      api.getMaterialTransactions(seller: true),
      api.getMaterialTransactions(seller: false),
    ]);
    final orders = await Future.wait([
      api.getProductOrders(seller: true),
      api.getProductOrders(seller: false),
    ]);
    bool done(String status) => status == 'Completed' || status == 'Delivered';
    final completed = transactions.expand((list) => list).where((t) => done(t.statusName)).length +
        orders.expand((list) => list).where((o) => done(o.statusName)).length;
    final sales = transactions[0].where((t) => done(t.statusName)).fold<double>(0, (sum, t) => sum + t.totalAmount) +
        orders[0].where((o) => done(o.statusName)).fold<double>(0, (sum, o) => sum + o.totalAmount);
    return _HomeStats(completed, sales);
  } finally {
    api.dispose();
  }
});

final _homeProductsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.read(productRepositoryProvider).getProducts(),
);

String _compact(double value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k'
    : value.toStringAsFixed(0);

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.onNavigate});

  final void Function(int bottomIndex, {int? topIndex})? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsyncValue = ref.watch(activeListingsNotifierProvider);
    final profileAsyncValue = ref.watch(profileNotifierProvider);
    final statsAsync = ref.watch(_homeStatsProvider);
    final productsAsync = ref.watch(_homeProductsProvider);

    // "Listed" = my active material listings + my products.
    final me = AppConfig.currentBusinessId;
    final listed = (listingsAsyncValue.hasValue && productsAsync.hasValue)
        ? '${listingsAsyncValue.value!.where((l) => l.businessId == me).length + productsAsync.value!.where((p) => p.businessId == me).length}'
        : '–';
    final completedDeals = statsAsync.hasValue ? '${statsAsync.value!.completedDeals}' : '–';
    final sales = statsAsync.hasValue ? _compact(statsAsync.value!.sales) : '–';

    final rawName = profileAsyncValue.value?.businessName ?? 'Eco Warrior';
    final nameParts = rawName.split(' ').where((p) => p.isNotEmpty).toList();
    final displayName = nameParts.length > 2 ? '${nameParts[0]} ${nameParts[1]}' : rawName;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: RefreshIndicator(
        color: AppColors.forestGreen,
        onRefresh: () async {
          ref.invalidate(activeListingsNotifierProvider);
          ref.invalidate(_homeStatsProvider);
          ref.invalidate(_homeProductsProvider);
          await ref.read(_homeProductsProvider.future).catchError((_) => <Product>[]);
        },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Custom Curved Header with Overlapping Stats
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Header Background
                Container(
                  height: 310,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.darkCharcoal, AppColors.forestGreen],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset('assets/images/logo_rounded.png', height: 32, width: 32, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'ECOLOOP',
                                      style: TextStyle(color: AppColors.mintGreen, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Good Morning,',
                                  style: TextStyle(color: AppColors.mintGreen, fontSize: 16),
                                ),
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.mintGreen, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.ecoGreen,
                              backgroundImage: profileAsyncValue.value?.logoUrl != null
                                  ? NetworkImage(profileAsyncValue.value!.logoUrl!)
                                  : null,
                              child: profileAsyncValue.value?.logoUrl == null
                                  ? Text(
                                      (profileAsyncValue.value?.businessName.isNotEmpty == true)
                                          ? profileAsyncValue.value!.businessName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 2. Overlapping Glassmorphism Stats Card
                Positioned(
                  top: 200,
                  left: 24,
                  right: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.95), // Slightly more opaque since no blur
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.white.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkCharcoal.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.eco, color: AppColors.ecoGreen, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Your Activity',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateGray),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Real data for the signed-in business.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Listed', listed, '', Icons.recycling),
                              _buildStatDivider(),
                              _buildStatColumn('Completed', completedDeals, '', Icons.handshake_outlined),
                              _buildStatDivider(),
                              _buildStatColumn('Sales', sales, '', Icons.payments_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 100), // Spacing for the overlapping card
            
            // 3. Quick Actions (Bold blocks instead of simple icons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkCharcoal),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildQuickAction(
                    context, 
                    'Post Material', 
                    Icons.add_box_rounded, 
                    AppColors.forestGreen,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMaterialPage())),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                    context, 
                    'Buy Products', 
                    Icons.shopping_bag_rounded, 
                    AppColors.rewardGold,
                    onTap: () {
                      if (onNavigate != null) {
                        onNavigate!(1, topIndex: 0);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                    context, 
                    'Track Order', 
                    Icons.local_shipping_rounded, 
                    AppColors.ecoGreen,
                    // Opens the Orders tab (transactions, orders, deliveries).
                    onTap: () => onNavigate?.call(2),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 4. Recent Marketplace Discoveries
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trending Materials',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkCharcoal),
                  ),
                  TextButton(
                    onPressed: () {
                      if (onNavigate != null) {
                        onNavigate!(1, topIndex: 1); // 1 = Marketplace, 1 = Materials
                      }
                    },
                    child: const Text('View All', style: TextStyle(color: AppColors.ecoGreen, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            listingsAsyncValue.when(
              loading: () => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
              ),
              error: (err, stack) => SizedBox(height: 80, child: Center(child: Text('Error: $err'))),
              data: (allListings) {
                final recentItems = allListings.take(4).toList();
                if (recentItems.isEmpty) {
                  // Compact empty state so the sections below stay on screen.
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('No materials listed yet', style: TextStyle(color: AppColors.slateGray)),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddMaterialPage()),
                          ),
                          icon: const Icon(Icons.add, color: AppColors.ecoGreen),
                          label: const Text('Post the first material', style: TextStyle(color: AppColors.ecoGreen)),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 220,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: recentItems.length,
                    itemBuilder: (context, index) {
                      return _buildTrendingCard(context, recentItems[index]);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // 5. Newest sustainable products
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkCharcoal),
                  ),
                  TextButton(
                    onPressed: () => onNavigate?.call(1, topIndex: 0), // Marketplace → Products
                    child: const Text('View All', style: TextStyle(color: AppColors.ecoGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (products) {
                  final recent = products.take(6).toList();
                  if (recent.isEmpty) {
                    return const Center(child: Text('No products listed yet'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: recent.length,
                    itemBuilder: (context, index) => _buildProductCard(context, recent[index]),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailsPage(productId: product.id)),
      ),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.mintGreen),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: product.primaryImageUrl != null
                    ? ProductImageWidget(imageUrl: product.primaryImageUrl)
                    : const ColoredBox(
                        color: AppColors.mintGreen,
                        child: Icon(Icons.shopping_bag_outlined, color: AppColors.forestGreen, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LKR ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    product.availableQuantity > 0 ? '${product.availableQuantity} in stock' : 'Out of stock',
                    style: const TextStyle(color: AppColors.slateGray, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.forestGreen, size: 28),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.darkCharcoal),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray),
              ),
            ]
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.mintGreen,
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color, {required VoidCallback onTap}) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, MaterialListing listing) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialDetailsPage(
              listing: listing,
              heroTag: 'hero_trending_${listing.id}',
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.mintGreen,
          boxShadow: [
            BoxShadow(
              color: AppColors.slateGray.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                listing.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.image_outlined, size: 64, color: AppColors.ecoGreen));
                },
              ),
            ),
            // Dark Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.darkCharcoal.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.rewardGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.category,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${listing.price.toStringAsFixed(0)}/${listing.priceUnit}',
                    style: const TextStyle(
                      color: AppColors.mintGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
