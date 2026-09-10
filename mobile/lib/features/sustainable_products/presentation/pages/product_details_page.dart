import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/product_repository.dart';
import '../../domain/entities/product.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;

  const ProductDetailsPage({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: FutureBuilder<Product>(
        future: repository.getProduct(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load product: ${snapshot.error}'),
            );
          }

          final product = snapshot.data;

          if (product == null) {
            return const Center(
              child: Text('Product not found.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (product.images.isNotEmpty)
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    itemCount: product.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        product.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) {
                          return const ColoredBox(
                            color: AppColors.mintGreen,
                            child: Icon(Icons.image_not_supported),
                          );
                        },
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 260,
                  color: AppColors.mintGreen,
                  child: const Icon(
                    Icons.recycling,
                    size: 80,
                    color: AppColors.forestGreen,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'LKR ${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.forestGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Material',
                value: product.materialType,
              ),
              _InfoRow(
                label: 'Category',
                value: product.category ?? 'Not specified',
              ),
              _InfoRow(
                label: 'Available quantity',
                value: product.availableQuantity.toString(),
              ),
              _InfoRow(
                label: 'Seller',
                value: product.seller ?? 'Unknown seller',
              ),
              if (product.sellerIsVerified)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.verified,
                    color: AppColors.forestGreen,
                  ),
                  title: Text('Verified seller'),
                ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: product.availableQuantity <= 0
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Order functionality requires an orders API.',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Request material'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slateGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}