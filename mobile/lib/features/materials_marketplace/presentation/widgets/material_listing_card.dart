import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';

class MaterialListingCard extends StatelessWidget {
  final MaterialListing listing;

  const MaterialListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: AppColors.ecoGreen),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.slateGray.withOpacity(0.3)),
                        ),
                        child: Text(
                          listing.category,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (listing.isVerifiedSeller)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check, color: AppColors.white, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                'VERIFIED SELLER',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    listing.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Quantity and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Qty: ${listing.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '\$${listing.price.toStringAsFixed(0)} / ${listing.priceUnit}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Location and Company
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.slateGray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${listing.location} • ${listing.companyName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
