import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/product_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions_delivery/data/services/component4_api_service.dart';
import '../../../transactions_delivery/domain/entities/transaction_models.dart';
import '../../../transactions_delivery/presentation/pages/location_picker_page.dart';
import '../../../transactions_delivery/presentation/pages/saved_locations_page.dart';
import '../../../transactions_delivery/presentation/pages/transaction_detail_page.dart';
import '../../../transactions_delivery/presentation/widgets/delivery_method_selector.dart';
import 'payment_page.dart';

class PurchaseProductPage extends ConsumerStatefulWidget {
  final Product product;

  const PurchaseProductPage({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<PurchaseProductPage> createState() => _PurchaseProductPageState();
}

class _PurchaseProductPageState extends ConsumerState<PurchaseProductPage> {
  int _quantity = 1;
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  final _api = Component4ApiService();
  // Seller Delivery is only offered when the seller enabled it for this product.
  DeliveryMethod _method = DeliveryMethod.selfPickup;
  String? _location;

  void _increment() {
    if (_quantity < widget.product.availableQuantity) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _processPurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_method == DeliveryMethod.sellerDelivery && _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose where the seller should deliver.')),
      );
      return;
    }

    final totalPrice = widget.product.price * _quantity;
    
    // Navigate to payment page
    final paymentSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentPage(totalAmount: totalPrice),
      ),
    );

    if (paymentSuccess != true) return; // User cancelled or failed

    setState(() => _isProcessing = true);
    
    try {
      // A product order (not a bare stock decrement) so the seller can confirm,
      // prepare and deliver it, and both sides can track it in Orders.
      final order = await _api.createProductOrder(
        items: [
          {'productId': widget.product.id, 'quantity': _quantity},
        ],
        method: _method,
        location: _method == DeliveryMethod.sellerDelivery ? _location : null,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: AppColors.forestGreen, size: 64),
              SizedBox(height: 16),
              Text('Purchase Successful!', textAlign: TextAlign.center),
            ],
          ),
          content: Text(
            _method == DeliveryMethod.sellerDelivery
                ? 'You ordered $_quantity x ${widget.product.name}. The seller will deliver it; follow it in Orders.'
                : 'You ordered $_quantity x ${widget.product.name}. You\'ll collect it from the seller; follow it in Orders.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // pop dialog
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailPage(id: order.id, order: true),
                    ),
                  );
                },
                child: const Text('Track Order'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // pop dialog
                  Navigator.of(context).pop(true); // pop purchase screen with true
                },
                child: const Text('Back to Product'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.product.price * _quantity;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Complete Purchase'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Product Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slateGray.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: widget.product.images.isNotEmpty
                            ? ProductImageWidget(
                                imageUrl: widget.product.images.first,
                                fit: BoxFit.cover,
                              )
                            : const ColoredBox(
                                color: AppColors.mintGreen,
                                child: Icon(Icons.recycling, color: AppColors.forestGreen),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${widget.product.price.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available: ${widget.product.availableQuantity}',
                            style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quantity Selector
              const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onTap: _quantity > 1 ? _decrement : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  _QuantityButton(
                    icon: Icons.add,
                    onTap: _quantity < widget.product.availableQuantity ? _increment : null,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Delivery: Self Pickup, or Seller Delivery when the seller offers it
              const Text('Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    DeliveryMethodSelector(
                      value: _method,
                      sellerDeliveryAvailable: widget.product.sellerDeliveryAvailable,
                      onChanged: (value) => setState(() => _method = value),
                    ),
                    if (_method == DeliveryMethod.sellerDelivery) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(_location ?? 'Choose delivery location'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickLocation(
                          LocationPickerPage(initialLocation: _location),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.bookmark_outline),
                        label: const Text('Use a saved location'),
                        onPressed: () => _pickLocation(
                          const SavedLocationsPage(select: true),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Order Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.mintGreen),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontSize: 16)),
                        Text(
                          'LKR ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPurchase,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 3),
                        )
                      : const Text('Confirm Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocation(Widget page) async {
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    if (value != null && mounted) setState(() => _location = value);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppColors.slateGray.withValues(alpha: 0.2) : AppColors.forestGreen,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: onTap == null ? AppColors.slateGray : AppColors.white),
        ),
      ),
    );
  }
}
