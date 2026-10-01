import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../transactions_delivery/data/services/component4_api_service.dart';
import '../../../transactions_delivery/presentation/pages/product_checkout_page.dart';
import '../../../transactions_delivery/presentation/pages/transactions_hub_page.dart';
import '../../domain/entities/product.dart';

class ProductsPage extends StatefulWidget {
  final Component4ApiService? api;
  const ProductsPage({super.key, this.api});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final _api = widget.api ?? Component4ApiService();
  late Future<List<Product>> _products;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _products = _api.getProducts();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _api.getProducts();
    setState(() => _products = future);
    // FutureBuilder displays the error and provides retry.
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sustainable Products'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'My orders',
          icon: const Icon(Icons.receipt_long),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TransactionsHubPage(initialIndex: 1),
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search products',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _search = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final products = (snapshot.data ?? [])
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(_search) ||
                        p.description.toLowerCase().contains(_search),
                  )
                  .toList();
              if (products.isEmpty) {
                return const Center(child: Text('No products found.'));
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _ProductCard(
                    key: ValueKey(products[index].id),
                    product: products[index],
                    onCheckout: (quantity) async {
                      final product = products[index];
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductCheckoutPage(
                            items: [
                              CheckoutItem(
                                productId: product.id,
                                name: product.name,
                                unitPrice: product.price,
                                quantity: quantity,
                                sellerDeliveryAvailable:
                                    product.sellerDeliveryAvailable,
                              ),
                            ],
                          ),
                        ),
                      );
                      if (mounted) await _refresh();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final ValueChanged<int> onCheckout;
  const _ProductCard({
    super.key,
    required this.product,
    required this.onCheckout,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _quantity = 1;

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_quantity > widget.product.availableQuantity) _quantity = 1;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final ownProduct = product.businessId == AppConfig.currentBusinessId;
    final canBuy = !ownProduct && product.availableQuantity > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name, style: Theme.of(context).textTheme.titleLarge),
            Text(product.seller ?? 'Seller'),
            if (product.description.isNotEmpty) Text(product.description),
            const SizedBox(height: 8),
            Text(
              '\$${product.price.toStringAsFixed(2)} · ${product.availableQuantity} available',
            ),
            Text(
              product.sellerDeliveryAvailable
                  ? 'Pickup or seller delivery'
                  : 'Self pickup',
            ),
            if (canBuy)
              Row(
                children: [
                  const Text('Quantity'),
                  IconButton(
                    tooltip: 'Decrease quantity',
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_quantity'),
                  IconButton(
                    tooltip: 'Increase quantity',
                    onPressed: _quantity < product.availableQuantity
                        ? () => setState(() => _quantity++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: canBuy ? () => widget.onCheckout(_quantity) : null,
              child: Text(
                ownProduct
                    ? 'Your product'
                    : canBuy
                    ? 'Buy Now'
                    : 'Out of stock',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
