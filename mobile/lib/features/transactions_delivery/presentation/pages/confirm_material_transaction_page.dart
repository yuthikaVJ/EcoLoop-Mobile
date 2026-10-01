import 'saved_locations_page.dart';
import 'package:flutter/material.dart';
import '../../../materials_marketplace/domain/entities/material_listing.dart';
import '../../data/services/component4_api_service.dart';
import '../../domain/entities/transaction_models.dart';
import '../widgets/delivery_method_selector.dart';
import 'location_picker_page.dart';
import 'transaction_detail_page.dart';

class ConfirmMaterialTransactionPage extends StatefulWidget {
  final MaterialListing listing;
  const ConfirmMaterialTransactionPage({super.key, required this.listing});

  @override
  State<ConfirmMaterialTransactionPage> createState() =>
      _ConfirmMaterialTransactionPageState();
}

class _ConfirmMaterialTransactionPageState
    extends State<ConfirmMaterialTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = Component4ApiService();
  late final TextEditingController _quantity;
  // Every transaction starts as an offer: the price per unit proposed to the
  // listing owner, who accepts or rejects it.
  late final TextEditingController _price;
  DeliveryMethod _method = DeliveryMethod.selfPickup;
  // Offers only: where the requester collects the material (Self Pickup).
  String? _pickupLocation;
  // Seller Delivery destination. For an offer it starts at the requester's
  // listing location.
  String? _deliveryLocation;
  bool _submitting = false;

  // Offering to supply an "I Need" listing: the supplier picks Self Pickup
  // (from their address) or Seller Delivery (they deliver to the requester).
  // Otherwise it is a buyer's offer on an "I Have" listing.
  bool get _isSupplyOffer => !widget.listing.isIHave;

  // The location the current method needs; a buyer's Self Pickup uses the
  // listing's own location.
  String? get _location => _method == DeliveryMethod.sellerDelivery
      ? _deliveryLocation
      : _isSupplyOffer
      ? _pickupLocation
      : widget.listing.location;

  bool get _needsLocationInput =>
      _method == DeliveryMethod.sellerDelivery || _isSupplyOffer;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '1');
    // A buyer's offer starts at the seller's asking price.
    final asking = widget.listing.price;
    _price = TextEditingController(
      text: _isSupplyOffer
          ? ''
          : asking == asking.roundToDouble()
          ? asking.toStringAsFixed(0)
          : asking.toString(),
    );
    final requesterLocation = widget.listing.location.trim();
    if (_isSupplyOffer &&
        requesterLocation.isNotEmpty &&
        requesterLocation != 'Unknown Location') {
      _deliveryLocation = requesterLocation;
    }
  }

  @override
  void dispose() {
    _api.dispose();
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  void _setLocation(String value) => setState(() {
    if (_method == DeliveryMethod.sellerDelivery) {
      _deliveryLocation = value;
    } else {
      _pickupLocation = value;
    }
  });

  Future<void> _chooseLocation() async {
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialLocation: _location),
      ),
    );
    if (value != null && mounted) _setLocation(value);
  }

  String get _locationPrompt => _method == DeliveryMethod.sellerDelivery
      ? (_isSupplyOffer
            ? 'Choose where to deliver'
            : 'Choose delivery location')
      : 'Choose your pickup location';

  double? get _offerTotal {
    final quantity = double.tryParse(_quantity.text);
    final price = double.tryParse(_price.text);
    return quantity == null || price == null ? null : quantity * price;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(widget.listing.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This listing is not available for transactions yet. Select a published listing.',
          ),
        ),
      );
      return;
    }
    if (_needsLocationInput && _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _method == DeliveryMethod.sellerDelivery
                ? 'Select a delivery location.'
                : 'Add your pickup location so the requester can collect it.',
          ),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final transaction = await _api.createMaterialTransaction(
        listingId: widget.listing.id,
        sellerBusinessId: widget.listing.isIHave
            ? widget.listing.businessId ?? ''
            : Component4Config.currentBusinessId,
        buyerBusinessId: widget.listing.isIHave
            ? Component4Config.currentBusinessId
            : widget.listing.businessId ?? '',
        quantity: double.parse(_quantity.text),
        unit: widget.listing.unit,
        unitPrice: double.parse(_price.text),
        method: _method,
        location: _location,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TransactionDetailPage(id: transaction.id, order: false),
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
    appBar: AppBar(
      title: Text(_isSupplyOffer ? 'Offer to Supply' : 'Make an Offer'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(widget.listing.title),
              subtitle: Text(
                widget.listing.companyName ??
                    (_isSupplyOffer ? 'Requester' : 'Seller'),
              ),
              trailing: _isSupplyOffer
                  ? null
                  : Text('Asking \$${widget.listing.price.toStringAsFixed(2)}'),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity (${widget.listing.unit})',
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final quantity = double.tryParse(value ?? '');
              return quantity == null || !quantity.isFinite || quantity <= 0
                  ? 'Enter a valid quantity.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _isSupplyOffer
                  ? 'Your price per ${widget.listing.unit}'
                  : 'Your offer per ${widget.listing.unit}',
              prefixText: '\$ ',
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final price = double.tryParse(value ?? '');
              return price == null || !price.isFinite || price < 0
                  ? 'Enter a valid price.'
                  : null;
            },
          ),
          if (_offerTotal != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Total: \$${_offerTotal!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Delivery Method',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          DeliveryMethodSelector(
            value: _method,
            // A supplier can always offer to deliver it themselves.
            sellerDeliveryAvailable:
                _isSupplyOffer || widget.listing.sellerDeliveryAvailable,
            selfPickupSubtitle: _isSupplyOffer
                ? 'The requester collects it from your location'
                : null,
            sellerDeliverySubtitle: _isSupplyOffer
                ? 'You deliver it to the requester'
                : null,
            onChanged: (value) => setState(() => _method = value),
          ),
          if (_needsLocationInput) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(_location ?? _locationPrompt),
              subtitle: _location == null
                  ? null
                  : Text(
                      _method == DeliveryMethod.sellerDelivery
                          ? 'Delivery location'
                          : 'Pickup location',
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _chooseLocation,
            ),
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
                if (value != null && mounted) _setLocation(value);
              },
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting...' : 'Send Offer'),
          ),
        ],
      ),
    ),
  );
}
