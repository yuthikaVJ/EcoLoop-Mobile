import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../business_hub/presentation/widgets/post_as_selector.dart';
import '../providers/material_listings_provider.dart';

class AddMaterialPage extends ConsumerStatefulWidget {
  final bool initialIsIHave;
  const AddMaterialPage({super.key, this.initialIsIHave = true});

  @override
  ConsumerState<AddMaterialPage> createState() => _AddMaterialPageState();
}

class _AddMaterialPageState extends ConsumerState<AddMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for text fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  
  // State variables for form fields
  late bool _isIHave;
  String? _selectedCategory;
  String _selectedUnit = 'Tons';
  String _deliveryOption = 'Self Pickup';
  // Optional details that help EcoLoop AI find better matches.
  String? _availability;
  final _conditionController = TextEditingController();
  static const _availabilityOptions = ['Immediately', 'Within a week', 'Flexible'];
  // Verified Business Hub profile to post as; null = personal account.
  String? _postAsBusinessId = defaultPostAsBusinessId();

  final List<String> _categories = [
    'Plastics', 'Paper', 'Metals', 'Glass', 'E-Waste', 'Wood', 'Other'
  ];
  final List<String> _units = ['Tons', 'Kgs', 'Units', 'Bales'];

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  static const _maxImages = 10;

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      _showMaxImagesMessage();
      return;
    }
    // Phone photos are often 3-8 MB; resizing keeps uploads fast and under
    // the server's limit while still looking sharp on screen.
    final selectedImages = await _picker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
      limit: remaining > 1 ? remaining : null,
    );
    if (selectedImages.isEmpty || !mounted) return;
    setState(() => _images.addAll(selectedImages.take(remaining)));
    if (selectedImages.length > remaining) _showMaxImagesMessage();
  }

  void _showMaxImagesMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A listing can have up to $_maxImages photos.')),
    );
  }

  @override
  void initState() {
    super.initState();
    _isIHave = widget.initialIsIHave;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkCharcoal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Material Listing', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      PostAsSelector(
                        value: _postAsBusinessId,
                        onChanged: (id) => setState(() => _postAsBusinessId = id),
                      ),

                      // Photo Upload Section
                      _buildSectionTitle('Photos'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickImages,
                              child: _buildPhotoPlaceholder(isAdd: true),
                            ),
                            const SizedBox(width: 12),
                            ..._images.map((img) => Padding(
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
                                          color: AppColors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // Empty placeholders if less than 2 images
                            if (_images.length < 2)
                              ...List.generate(2 - _images.length, (index) => Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: _buildPhotoPlaceholder(),
                              )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

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
                                onTap: () => setState(() => _isIHave = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isIHave ? AppColors.forestGreen : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _isIHave ? [
                                      BoxShadow(
                                        color: AppColors.forestGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'I Have',
                                      style: TextStyle(
                                        color: _isIHave ? AppColors.white : AppColors.forestGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isIHave = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isIHave ? AppColors.forestGreen : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: !_isIHave ? [
                                      BoxShadow(
                                        color: AppColors.forestGreen.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'I Need',
                                      style: TextStyle(
                                        color: !_isIHave ? AppColors.white : AppColors.forestGreen,
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
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Mixed High-Density Polyethylene',
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                      ),

                      // Category
                      _buildSectionTitle('Category'),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        hint: const Text('Select Category'),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        validator: (value) => value == null ? 'Please select a category' : null,
                      ),

                      // Description
                      _buildSectionTitle('Description'),
                      TextFormField(
                        controller: _descController,
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
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'e.g. 15.5'),
                                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
                                    return DropdownMenuItem(value: unit, child: Text(unit));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedUnit = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Price
                      if (_isIHave) ...[
                        _buildSectionTitle('Price (per $_selectedUnit)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '\$ ',
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ],

                      // Location
                      _buildSectionTitle('Location'),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'Pickup address',
                          prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.slateGray),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
                              if (selected) setState(() => _deliveryOption = 'Self Pickup');
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Seller Delivery'),
                            selected: _deliveryOption == 'Seller Delivery',
                            selectedColor: AppColors.mintGreen,
                            onSelected: (bool selected) {
                              if (selected) setState(() => _deliveryOption = 'Seller Delivery');
                            },
                          ),
                        ],
                      ),

                      // Optional details for AI matching
                      _buildSectionTitle(_isIHave ? 'Available (optional)' : 'Needed (optional)'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final option in _availabilityOptions)
                            ChoiceChip(
                              label: Text(option),
                              selected: _availability == option,
                              selectedColor: AppColors.mintGreen,
                              onSelected: (selected) =>
                                  setState(() => _availability = selected ? option : null),
                            ),
                        ],
                      ),
                      _buildSectionTitle('Condition (optional)'),
                      TextFormField(
                        controller: _conditionController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Clean and sorted, mixed, baled',
                          prefixIcon: Icon(Icons.fact_check_outlined, color: AppColors.slateGray),
                        ),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, size: 14, color: AppColors.ecoGreen),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'EcoLoop AI uses these details to find matching posts for you.',
                              style: TextStyle(fontSize: 12, color: AppColors.slateGray),
                            ),
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
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final requestData = {
                          "title": _titleController.text,
                          "category": _selectedCategory ?? 'Other',
                          "description": _descController.text,
                          "quantity": _quantityController.text,
                          "unit": _selectedUnit,
                          "location": _locationController.text,
                          "price": _isIHave ? (double.tryParse(_priceController.text) ?? 0.0) : 0.0,
                          "priceUnit": _selectedUnit,
                          "deliveryMethod": _deliveryOption,
                          // Lets buyers choose Seller Delivery (the seller delivers; no EcoLoop fleet).
                          "sellerDeliveryAvailable": _deliveryOption == 'Seller Delivery',
                          "type": _isIHave ? 0 : 1, // 0 = I Have, 1 = I Need
                          if (_postAsBusinessId != null)
                            "postedAsBusinessId": _postAsBusinessId,
                          if (_availability != null) "availability": _availability,
                          if (_conditionController.text.trim().isNotEmpty)
                            "condition": _conditionController.text.trim(),
                        };

                        await ref.read(activeListingsNotifierProvider.notifier).addListing(
                          requestData,
                          imageFiles: [for (final image in _images) File(image.path)],
                        );
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Listing posted! EcoLoop AI is looking for matches - we\'ll notify you.'),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to post: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Post Listing', style: TextStyle(fontSize: 16)),
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
          color: isAdd ? AppColors.ecoGreen : AppColors.slateGray.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          isAdd ? Icons.add_a_photo : Icons.image_outlined,
          color: isAdd ? AppColors.ecoGreen : AppColors.slateGray.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }
}
