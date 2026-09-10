import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import 'chat_page.dart';

class MaterialDetailsPage extends StatelessWidget {
  final MaterialListing listing;
  final String heroTag;

  const MaterialDetailsPage({
    super.key,
    required this.listing,
    required this.heroTag,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) return '${difference.inMinutes} mins ago';
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    }
    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            iconTheme: const IconThemeData(color: AppColors.white),
            backgroundColor: AppColors.forestGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: heroTag,
                    child: Container(
                      color: AppColors.mintGreen,
                      child: const Icon(Icons.image_outlined, size: 100, color: AppColors.ecoGreen),
                    ),
                  ),
                  // Dark gradient overlay for text readability if we add title to FlexibleSpaceBar
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mintGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.category,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (listing.isVerifiedSeller)
                        Row(
                          children: [
                            const Icon(Icons.verified, color: AppColors.forestGreen, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Seller',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Title & Price
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${listing.price.toStringAsFixed(0)} / ${listing.priceUnit}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Specifications Grid
                  const Text('Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.mintGreen),
                    ),
                    child: Column(
                      children: [
                        _buildSpecRow(Icons.inventory_2_outlined, 'Quantity', listing.quantity),
                        const Divider(height: 24),
                        _buildSpecRow(Icons.location_on_outlined, 'Location', listing.location),
                        const Divider(height: 24),
                        _buildSpecRow(Icons.local_shipping_outlined, 'Delivery', 'Seller Delivery / Self Pickup'),
                        const Divider(height: 24),
                        _buildSpecRow(Icons.access_time_outlined, 'Date Posted', _formatDate(listing.datePosted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(
                    'This is a placeholder description for ${listing.title}. Here the seller would provide detailed information regarding the quality, exact condition, and any other relevant specifics about the material being offered or requested.',
                    style: const TextStyle(height: 1.5, color: AppColors.slateGray),
                  ),
                  const SizedBox(height: 24),
                  
                  // Seller Info
                  const Text('Seller Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.mintGreen,
                      child: Text(
                        listing.companyName.substring(0, 1),
                        style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(listing.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Member since 2024 • 4.8 Rating'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  
                  const SizedBox(height: 80), // Bottom padding for FAB/BottomBar
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.slateGray.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage(listing: listing)),
            );
          },
          child: const Text('Contact Seller', style: TextStyle(fontSize: 16, color: AppColors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ecoGreen, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.slateGray)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
