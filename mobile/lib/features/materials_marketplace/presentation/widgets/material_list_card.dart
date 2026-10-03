import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../../../sustainable_products/presentation/widgets/product_image_widget.dart';
import '../../../../shared/widgets/seller_name.dart';

/// Compact, full-width listing card used by the Materials marketplace list.
/// Thumbnail on the left, details on the right; the same shape as
/// [MaterialListCardSkeleton] so loading doesn't shift the layout.
class MaterialListCard extends StatelessWidget {
  final MaterialListing listing;
  final String heroTag;
  final VoidCallback onTap;

  const MaterialListCard({
    super.key,
    required this.listing,
    required this.heroTag,
    required this.onTap,
  });

  static const double thumbnailSize = 84;

  // Listings without a photo carry a dead placeholder URL; treat it as "none".
  String? get _imageUrl {
    final url = listing.imageUrl;
    return url.isEmpty || url.contains('placeholder.com') ? null : url;
  }

  @override
  Widget build(BuildContext context) {
    final quantity = '${listing.quantity} ${listing.unit}'.trim();
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mintGreen),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: thumbnailSize,
                    child: ColoredBox(
                      color: AppColors.mintGreen,
                      child: _imageUrl == null
                          ? const Icon(
                              Icons.recycling,
                              color: AppColors.ecoGreen,
                              size: 32,
                            )
                          : ProductImageWidget(imageUrl: _imageUrl),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.slateGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (listing.sellerDeliveryAvailable)
                          const _Tag(
                            icon: Icons.local_shipping_outlined,
                            label: 'Delivery',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkCharcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // "I Need" listings have no asking price (it's saved as 0).
                    Text(
                      listing.isIHave
                          ? '\$${listing.price.toStringAsFixed(listing.price % 1 == 0 ? 0 : 2)} / ${listing.priceUnit}'
                          : 'Wanted',
                      style: const TextStyle(
                        color: AppColors.forestGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Meta(icon: Icons.inventory_2_outlined, text: quantity),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Meta(
                            icon: Icons.location_on_outlined,
                            text: listing.location,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SellerName(
                      name: listing.companyName,
                      verified: listing.isVerifiedSeller,
                      style: const TextStyle(
                        color: AppColors.slateGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.slateGray),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.slateGray, fontSize: 12),
        ),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.mintGreen,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.forestGreen),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.forestGreen,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
