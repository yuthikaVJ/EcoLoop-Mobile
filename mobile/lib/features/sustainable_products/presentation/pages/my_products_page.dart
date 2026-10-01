import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/product.dart';
import '../../data/product_repository.dart';
import 'product_details_page.dart';
import '../widgets/product_image_widget.dart';
import 'edit_product_page.dart';

class MyProductsPage extends ConsumerStatefulWidget {
  const MyProductsPage({super.key});

  @override
  ConsumerState<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends ConsumerState<MyProductsPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ref.read(productRepositoryProvider).getProducts(search: '');
  }

  Future<void> _refresh() async {
    setState(() {
      _productsFuture = ref.read(productRepositoryProvider).getProducts(search: '');
    });
    await _productsFuture;
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      // The dialog has its own context; after it closes, only the page's
      // `context` may be used (for snackbars).
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(productRepositoryProvider).deleteProduct(product.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted')),
                  );
                  _refresh();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAsSold(Product product) {
    showDialog(
      context: context,
      // The dialog has its own context; after it closes, only the page's
      // `context` may be used (for snackbars).
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Sold'),
        content: Text('Are you sure you want to mark "${product.name}" as sold? This will set available quantity to 0.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(productRepositoryProvider).markAsSold(product.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product marked as sold')),
                  );
                  _refresh();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to mark as sold: $e')),
                  );
                }
              }
            },
            child: const Text('Mark Sold'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load products: ${snapshot.error}'),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allProducts = snapshot.data ?? [];
          // Filter to only show products posted by the current user (using businessId)
          final myProducts = profile != null 
              ? allProducts.where((p) => p.businessId == profile.id).toList()
              : <Product>[];

          if (myProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.slateGray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'You have no products listed.',
                    style: TextStyle(color: AppColors.slateGray, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.forestGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myProducts.length,
              itemBuilder: (context, index) {
                final product = myProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      final refreshed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(productId: product.id),
                        ),
                      );
                      if (refreshed == true) {
                        _refresh();
                      }
                    },
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: ProductImageWidget(
                                imageUrl: product.primaryImageUrl,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product.category ?? 'Sustainable Product',
                                      style: const TextStyle(color: AppColors.slateGray, fontSize: 12),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'LKR ${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              color: AppColors.forestGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        Text(
                                          '${product.availableQuantity} left',
                                          style: TextStyle(
                                            color: product.availableQuantity > 0 
                                                ? AppColors.slateGray 
                                                : AppColors.errorRed,
                                            fontSize: 12,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen.withOpacity(0.1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EditProductPage(product: product)),
                                  );
                                  if (result == true) _refresh();
                                },
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.slateGray),
                                label: const Text('Edit', style: TextStyle(color: AppColors.slateGray)),
                              ),
                              TextButton.icon(
                                onPressed: product.availableQuantity > 0 ? () => _markAsSold(product) : null,
                                icon: Icon(Icons.check_circle_outline, size: 18, color: product.availableQuantity > 0 ? AppColors.forestGreen : AppColors.slateGray),
                                label: Text('Mark Sold', style: TextStyle(color: product.availableQuantity > 0 ? AppColors.forestGreen : AppColors.slateGray)),
                              ),
                              TextButton.icon(
                                onPressed: () => _deleteProduct(product),
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
