import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';

class GridMaterialCard extends StatelessWidget {
  final MaterialListing listing;
  final VoidCallback onTap;

  const GridMaterialCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mintGreen, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.slateGray.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Expanded(
              flex: 3,
              child: Hero(
                tag: 'hero_grid_${listing.id}',
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined, color: AppColors.ecoGreen),
                  ),
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.slateGray,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Qty: ${listing.quantity}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        Text(
                          '\$${listing.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
