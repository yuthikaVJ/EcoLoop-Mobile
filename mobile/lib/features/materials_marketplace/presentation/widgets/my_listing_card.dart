import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';

class MyListingCard extends StatelessWidget {
  final MaterialListing listing;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMarkSold;

  const MyListingCard({
    super.key,
    required this.listing,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
    this.onMarkSold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mintGreen),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateGray.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Content Row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined, color: AppColors.ecoGreen),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              listing.isIHave ? 'OFFERING' : 'REQUESTING',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                letterSpacing: 0.5,
                                color: listing.isIHave ? AppColors.forestGreen : AppColors.ecoGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            isActive ? 'Active' : 'Completed',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isActive ? AppColors.ecoGreen : AppColors.slateGray,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listing.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Qty: ${listing.quantity}', style: const TextStyle(color: AppColors.slateGray, fontSize: 12)),
                          Text(
                            '\$${listing.price.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons Divider
          Divider(height: 1, color: AppColors.mintGreen.withOpacity(0.5)),
          
          // Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isActive)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.slateGray),
                    label: const Text('Edit', style: TextStyle(color: AppColors.slateGray)),
                  ),
                if (isActive)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ),
                if (isActive && onMarkSold != null)
                  TextButton.icon(
                    onPressed: onMarkSold,
                    icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.forestGreen),
                    label: const Text('Mark Sold', style: TextStyle(color: AppColors.forestGreen)),
                  ),
                  
                if (!isActive)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    label: const Text('Remove History', style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
