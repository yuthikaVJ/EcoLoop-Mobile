import 'package:flutter/material.dart';
import '../../domain/entities/transaction_models.dart';

class DeliveryMethodSelector extends StatelessWidget {
  final DeliveryMethod value;
  final bool sellerDeliveryAvailable;
  final ValueChanged<DeliveryMethod> onChanged;
  // Override the buyer-facing descriptions, e.g. for a supplier making an offer.
  final String? selfPickupSubtitle;
  final String? sellerDeliverySubtitle;

  const DeliveryMethodSelector({
    super.key,
    required this.value,
    required this.sellerDeliveryAvailable,
    required this.onChanged,
    this.selfPickupSubtitle,
    this.sellerDeliverySubtitle,
  });

  @override
  Widget build(BuildContext context) => RadioGroup<DeliveryMethod>(
    groupValue: value,
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
    child: Column(
      children: [
        RadioListTile<DeliveryMethod>(
          value: DeliveryMethod.selfPickup,
          title: const Text('Self Pickup'),
          subtitle: Text(
            selfPickupSubtitle ?? 'Collect directly from the seller',
          ),
          secondary: const Icon(Icons.storefront_outlined),
        ),
        RadioListTile<DeliveryMethod>(
          value: DeliveryMethod.sellerDelivery,
          enabled: sellerDeliveryAvailable,
          title: const Text('Seller Delivery'),
          subtitle: Text(
            !sellerDeliveryAvailable
                ? 'Not available for this item'
                : sellerDeliverySubtitle ?? 'The seller will deliver this item',
          ),
          secondary: const Icon(Icons.local_shipping_outlined),
        ),
      ],
    ),
  );
}
