import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'data/product_repository.dart';
import 'domain/entities/product.dart';
import 'presentation/pages/product_details_page.dart';
import 'presentation/pages/add_product_page.dart';
import 'presentation/widgets/product_image_widget.dart';

class SustainableProductMarketplacePage extends ConsumerStatefulWidget {
  const SustainableProductMarketplacePage({super.key});

  @override
  ConsumerState<SustainableProductMarketplacePage> createState() =>
      _SustainableProductMarketplacePageState();
}

class _SustainableProductMarketplacePageState
    extends ConsumerState<SustainableProductMarketplacePage> {
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture =
        ref.read(productRepositoryProvider).getProducts(search: '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = ref.read(productRepositoryProvider).getProducts(
            search: _searchController.text,
          );
    });
  }

  Future<void> _refresh() async {
    _loadProducts();
    await _productsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadProducts(),
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadProducts();
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Grid ─────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                // Loading → show shimmer skeleton grid
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _SkeletonGrid();
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _loadProducts,
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco,
                            size: 64, color: AppColors.mintGreen),
                        SizedBox(height: 12),
                        Text('No products yet.',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Tap + to list your first eco product.',
                            style:
                                TextStyle(color: AppColors.slateGray)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: GridView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    // addRepaintBoundaries isolates each card's repaint
                    addRepaintBoundaries: true,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return RepaintBoundary(
                        child: _ProductCard(
                          product: product,
                          onTap: () async {
                            final refreshed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsPage(
                                  productId: product.id,
                                ),
                              ),
                            );
                            if (refreshed == true) {
                              _loadProducts();
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        tooltip: 'List a product',
        onPressed: () async {
          final refreshed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
          if (refreshed == true) _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Skeleton grid shown while loading ────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — smart widget handles base64 + network + null
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: ProductImageWidget(
                  imageUrl: product.primaryImageUrl,
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.category ?? 'Sustainable Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.slateGray, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'LKR ${product.price.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                      Text(
                        '${product.availableQuantity} left',
                        style: TextStyle(
                          color: product.availableQuantity > 0 
                              ? AppColors.slateGray 
                              : AppColors.errorRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load products.'),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}