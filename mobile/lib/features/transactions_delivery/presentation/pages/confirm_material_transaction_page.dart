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
  State<ConfirmMaterialTransactionPage> createState() => _ConfirmMaterialTransactionPageState();
}

class _ConfirmMaterialTransactionPageState extends State<ConfirmMaterialTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = Component4ApiService();
  late final TextEditingController _quantity;
  DeliveryMethod _method = DeliveryMethod.selfPickup;
  String? _location;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _chooseLocation() async {
    final value = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => LocationPickerPage(initialLocation: _location)));
    if (value != null) setState(() => _location = value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_method == DeliveryMethod.sellerDelivery && _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a delivery location.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final transaction = await _api.createMaterialTransaction(
        listingId: widget.listing.id,
        sellerBusinessId: widget.listing.businessId,
        quantity: double.parse(_quantity.text),
        unit: widget.listing.unit,
        unitPrice: widget.listing.price,
        method: _method,
        location: _location,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TransactionDetailPage(id: transaction.id, order: false)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Confirm Transaction')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(child: ListTile(title: Text(widget.listing.title), subtitle: Text(widget.listing.companyName), trailing: Text('\$${widget.listing.price.toStringAsFixed(2)}'))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Quantity (${widget.listing.unit})'),
                validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter a valid quantity.' : null,
              ),
              const SizedBox(height: 20),
              Text('Delivery Method', style: Theme.of(context).textTheme.titleLarge),
              DeliveryMethodSelector(value: _method, sellerDeliveryAvailable: widget.listing.sellerDeliveryAvailable, onChanged: (value) => setState(() => _method = value)),
              if (_method == DeliveryMethod.sellerDelivery)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(_location ?? 'Choose delivery location'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _chooseLocation,
                ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitting ? null : _submit, child: Text(_submitting ? 'Submitting...' : 'Submit Request')),
            ],
          ),
        ),
      );
}
