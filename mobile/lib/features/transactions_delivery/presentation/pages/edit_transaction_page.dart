import 'package:flutter/material.dart';
import '../../data/services/component4_api_service.dart';
import '../../domain/entities/transaction_models.dart';

class EditTransactionPage extends StatefulWidget {
  final MaterialTransactionDetails transaction;
  const EditTransactionPage({super.key, required this.transaction});
  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _form = GlobalKey<FormState>();
  final _api = Component4ApiService();
  late final _quantity = TextEditingController(
    text: widget.transaction.quantity.toString(),
  );
  late final _unit = TextEditingController(text: widget.transaction.unit);
  late final _price = TextEditingController(
    text: widget.transaction.unitPrice.toString(),
  );
  bool _busy = false;
  @override
  void dispose() {
    _quantity.dispose();
    _unit.dispose();
    _price.dispose();
    _api.dispose();
    super.dispose();
  }

  String? _number(String? text, bool price) {
    final value = double.tryParse(text ?? '');
    if (value == null || !value.isFinite || (price ? value < 0 : value <= 0)) {
      return 'Enter a valid amount.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _api.updateMaterial(
        widget.transaction,
        double.parse(_quantity.text),
        _unit.text.trim(),
        double.parse(_price.text),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Pending Request')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'These proposed terms remain subject to seller acceptance.',
          ),
          TextFormField(
            controller: _quantity,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => _number(v, false),
          ),
          TextFormField(
            controller: _unit,
            maxLength: 50,
            decoration: const InputDecoration(labelText: 'Unit'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a unit.' : null,
          ),
          TextFormField(
            controller: _price,
            decoration: const InputDecoration(labelText: 'Proposed unit price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => _number(v, true),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving...' : 'Save Request'),
          ),
        ],
      ),
    ),
  );
}
