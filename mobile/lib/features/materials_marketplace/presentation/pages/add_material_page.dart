import '../../domain/entities/material_listing.dart';
import '../../../transactions_delivery/data/services/component4_api_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';

class AddMaterialPage extends StatefulWidget {
  final MaterialListing? listing;
  const AddMaterialPage({super.key, this.listing});

  @override
  State<AddMaterialPage> createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends State<AddMaterialPage> {
  final _formKey = GlobalKey<FormState>();

  final _api = Component4ApiService();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    if (listing != null) {
      _name.text = listing.title;
      _description.text = listing.description;
      _quantity.text = listing.quantityValue;
      _price.text = listing.price.toString();
      _location.text = listing.location;
      _isIHave = listing.isIHave;
      _selectedCategory = _categories.firstWhere(
        (c) => c.toLowerCase() == listing.category.toLowerCase(),
        orElse: () => 'Other',
      );
      if (!_units.contains(listing.unit)) _units.add(listing.unit);
      _selectedUnit = listing.unit;
      _deliveryOption = listing.sellerDeliveryAvailable
          ? 'Seller Delivery'
          : 'Self Pickup';
    }
  }

  @override
  void dispose() {
    _api.dispose();
    for (final controller in [
      _name,
      _description,
      _quantity,
      _price,
      _location,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateNumber(String? value, {bool allowZero = false}) {
    final number = double.tryParse(value ?? '');
    return number == null ||
            !number.isFinite ||
            (allowZero ? number < 0 : number <= 0)
        ? 'Enter a valid number'
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'title': _name.text.trim(),
        'description': _description.text.trim(),
        'category': _selectedCategory!,
        'quantity': _quantity.text.trim(),
        'unit': _selectedUnit,
        'price': double.parse(_price.text),
        'priceUnit': widget.listing?.unit == _selectedUnit
            ? widget.listing!.priceUnit
            : _selectedUnit,
        'location': _location.text.trim(),
        'type': _isIHave ? 0 : 1,
        'deliveryMethod': _deliveryOption,
        'sellerDeliveryAvailable': _deliveryOption == 'Seller Delivery',
        if (widget.listing != null) 'imageUrl': widget.listing!.imageUrl,
      };
      await _api.saveMaterialListing(
        id: widget.listing?.id,
        fields: fields,
        imageBytes: _images.isEmpty ? null : await _images.first.readAsBytes(),
        imageName: _images.isEmpty ? null : _images.first.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing saved.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // State variables for form fields
  bool _isIHave = true;
  String? _selectedCategory;
  String _selectedUnit = 'Tons';
  String _deliveryOption = 'Self Pickup';

  final List<String> _categories = [
    'Plastics',
    'Paper',
    'Metals',
    'Glass',
    'E-Waste',
    'Wood',
    'Other',
  ];
  final List<String> _units = ['Tons', 'Kgs', 'Units', 'Bales'];

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  Future<void> _pickImages() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() {
        _images.clear();
        _images.add(image);
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.darkCharcoal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listing == null
              ? 'Add Material Listing'
              : 'Edit Material Listing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.listing == null) ...[
                        // Photo Upload Section
                        _buildSectionTitle('Photo'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: widget.listing == null
                                    ? _pickImages
                                    : null,
                                child: _buildPhotoPlaceholder(isAdd: true),
                              ),
                              const SizedBox(width: 12),
                              ..._images.map(
                                (img) => Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(img.path),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _images.remove(img);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: AppColors.white
                                                  .withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Empty placeholders if less than 2 images
                              if (_images.isEmpty)
                                ...List.generate(
                                  1 - _images.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: _buildPhotoPlaceholder(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Toggle I Have / I Need
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.mintGreen.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.listing == null
                                    ? () => setState(() => _isIHave = true)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isIHave
                                        ? AppColors.forestGreen
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _isIHave
                                        ? [
                                            BoxShadow(
                                              color: AppColors.forestGreen
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'I Have',
                                      style: TextStyle(
                                        color: _isIHave
                                            ? AppColors.white
                                            : AppColors.forestGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: widget.listing == null
                                    ? () => setState(() => _isIHave = false)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isIHave
                                        ? AppColors.forestGreen
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: !_isIHave
                                        ? [
                                            BoxShadow(
                                              color: AppColors.forestGreen
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'I Need',
                                      style: TextStyle(
                                        color: !_isIHave
                                            ? AppColors.white
                                            : AppColors.forestGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Material Name
                      _buildSectionTitle('Material Name'),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Mixed High-Density Polyethylene',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Please enter a name'
                            : null,
                      ),

                      // Category
                      _buildSectionTitle('Category'),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text('Select Category'),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                      ),

                      // Description
                      _buildSectionTitle('Description'),
                      TextFormField(
                        controller: _description,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe the condition, source, etc...',
                        ),
                      ),

                      // Quantity and Price
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Quantity'),
                                TextFormField(
                                  controller: _quantity,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 15.5',
                                  ),
                                  validator: (value) => _validateNumber(value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Unit'),
                                DropdownButtonFormField<String>(
                                  value: _selectedUnit,
                                  items: _units.map((unit) {
                                    return DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedUnit = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Price
                      _buildSectionTitle('Price (per $_selectedUnit)'),
                      TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          prefixText: '\$ ',
                        ),
                        validator: (value) =>
                            _validateNumber(value, allowZero: true),
                      ),

                      // Location
                      _buildSectionTitle('Location'),
                      TextFormField(
                        controller: _location,
                        decoration: const InputDecoration(
                          hintText: 'Pickup address',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppColors.slateGray,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),

                      // Delivery Option
                      _buildSectionTitle('Delivery Options'),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Self Pickup'),
                            selected: _deliveryOption == 'Self Pickup',
                            selectedColor: AppColors.mintGreen,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() => _deliveryOption = 'Self Pickup');
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Seller Delivery'),
                            selected: _deliveryOption == 'Seller Delivery',
                            selectedColor: AppColors.mintGreen,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(
                                  () => _deliveryOption = 'Seller Delivery',
                                );
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slateGray.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? 'Saving...'
                        : widget.listing == null
                        ? 'Post Listing'
                        : 'Save Changes',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder({bool isAdd = false}) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.mintGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdd
              ? AppColors.ecoGreen
              : AppColors.slateGray.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          isAdd ? Icons.add_a_photo : Icons.image_outlined,
          color: isAdd
              ? AppColors.ecoGreen
              : AppColors.slateGray.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }
}
