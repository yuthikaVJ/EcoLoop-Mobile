import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../materials_marketplace/domain/entities/material_listing.dart';
import '../../../materials_marketplace/presentation/pages/material_details_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Take a few dummy items for the 'Recent Discoveries' section
    final recentItems = dummyListings.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Custom Curved Header with Overlapping Stats
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Header Background
                Container(
                  height: 260,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Good Morning,',
                                style: TextStyle(color: AppColors.mintGreen, fontSize: 16),
                              ),
                              Text(
                                'NovaFlow',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.mintGreen, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.ecoGreen,
                              child: Text('NF', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 2. Overlapping Glassmorphism Stats Card
                Positioned(
                  top: 150,
                  left: 24,
                  right: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
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
                                  'Your Impact This Month',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateGray),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn('Recycled', '450', 'kg', Icons.recycling),
                                _buildStatDivider(),
                                _buildStatColumn('Saved', '12', 'trees', Icons.park),
                                _buildStatDivider(),
                                _buildStatColumn('Earned', '\$1.2k', '', Icons.attach_money),
                              ],
                            ),
                          ],
                        ),
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
                  _buildQuickAction(context, 'Post Material', Icons.add_box_rounded, AppColors.forestGreen),
                  const SizedBox(width: 16),
                  _buildQuickAction(context, 'Buy Products', Icons.shopping_bag_rounded, AppColors.rewardGold),
                  const SizedBox(width: 16),
                  _buildQuickAction(context, 'Track Order', Icons.local_shipping_rounded, AppColors.ecoGreen),
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
                      // We will let AppShell handle the navigation or just switch tabs
                    },
                    child: const Text('View All', style: TextStyle(color: AppColors.ecoGreen, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
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
            ),
            
            const SizedBox(height: 40),
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

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, Color color) {
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
          onTap: () {},
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
            // Background Image Placeholder (Icon)
            const Center(
              child: Icon(Icons.image_outlined, size: 64, color: AppColors.ecoGreen),
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
