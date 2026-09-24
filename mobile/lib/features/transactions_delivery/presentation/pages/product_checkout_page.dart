import 'saved_locations_page.dart';
import 'package:flutter/material.dart';
import '../../data/services/component4_api_service.dart';
import '../../domain/entities/transaction_models.dart';
import '../widgets/delivery_method_selector.dart';
import 'location_picker_page.dart';
import 'transaction_detail_page.dart';

class CheckoutItem {
  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final bool sellerDeliveryAvailable;

  const CheckoutItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.sellerDeliveryAvailable,
  });
}

class ProductCheckoutPage extends StatefulWidget {
  final List<CheckoutItem> items;
  const ProductCheckoutPage({super.key, required this.items});

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  final _api = Component4ApiService();
  DeliveryMethod _method = DeliveryMethod.selfPickup;
  String? _location;
  bool _submitting = false;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  bool get _sellerDeliveryAvailable =>
      widget.items.isNotEmpty &&
      widget.items.every((x) => x.sellerDeliveryAvailable);
  double get _total => widget.items.fold(
    0,
    (total, item) => total + item.unitPrice * item.quantity,
  );

  Future<void> _submit() async {
    if (widget.items.isEmpty) return;
    if (widget.items.any(
      (x) => x.quantity <= 0 || !x.unitPrice.isFinite || x.unitPrice < 0,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check item quantities and prices before ordering.'),
        ),
      );
      return;
    }
    if (_method == DeliveryMethod.sellerDelivery && _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a delivery location.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final order = await _api.createProductOrder(
        items: widget.items
            .map((x) => {'productId': x.productId, 'quantity': x.quantity})
            .toList(),
        method: _method,
        location: _method == DeliveryMethod.sellerDelivery ? _location : null,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(id: order.id, order: true),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confirm Order')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...widget.items.map(
          (item) => Card(
            child: ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
              ),
              trailing: Text(
                '\$${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Delivery Method', style: Theme.of(context).textTheme.titleLarge),
        DeliveryMethodSelector(
          value: _method,
          sellerDeliveryAvailable: _sellerDeliveryAvailable,
          onChanged: (value) => setState(() => _method = value),
        ),
        if (_method == DeliveryMethod.sellerDelivery)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(_location ?? 'Choose delivery location'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final value = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LocationPickerPage(initialLocation: _location),
                ),
              );
              if (value != null && mounted) setState(() => _location = value);
            },
          ),
        if (_method == DeliveryMethod.sellerDelivery)
          TextButton.icon(
            icon: const Icon(Icons.bookmark_outline),
            label: const Text('Use a saved location'),
            onPressed: () async {
              final value = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedLocationsPage(select: true),
                ),
              );
              if (value != null && mounted) setState(() => _location = value);
            },
          ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '\$${_total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitting || widget.items.isEmpty ? null : _submit,
          child: Text(_submitting ? 'Placing Order...' : 'Place Order'),
        ),
      ],
    ),
  );
}
