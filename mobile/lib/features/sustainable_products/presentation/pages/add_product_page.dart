import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/product_repository.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _materialController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;
  bool _submitting = false;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  static const _defaultBusinessId = '11111111-1111-1111-1111-111111111111';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _materialController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> selected = await _picker.pickMultiImage(imageQuality: 70);
    if (selected.isNotEmpty) {
      setState(() => _images.addAll(selected));
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null) {
      setState(() => _images.add(photo));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.mintGreen,
                  child: Icon(Icons.photo_library, color: AppColors.forestGreen),
                ),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.mintGreen,
                  child: Icon(Icons.camera_alt, color: AppColors.forestGreen),
                ),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ref.read(productRepositoryProvider).getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  /// Convert an XFile to a base64 data URL so the backend can store it.
  Future<String> _toDataUrl(XFile file) async {
    final bytes = await File(file.path).readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Create the product
      final productBody = jsonEncode({
        'categoryId': _selectedCategoryId,
        'businessId': _defaultBusinessId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'materialType': _materialController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'availableQuantity': int.parse(_stockController.text.trim()),
      });

      final productResponse = await apiClient.post('/api/products', body: productBody);

      if (!mounted) return;

      if (productResponse.statusCode != 201 && productResponse.statusCode != 200) {
        final msg = productResponse.body.isNotEmpty
            ? productResponse.body
            : 'Error (${productResponse.statusCode})';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create product: $msg'), backgroundColor: AppColors.errorRed),
        );
        return;
      }

      final createdProduct = jsonDecode(productResponse.body);
      final String productId = createdProduct['id'].toString();

      // 2. Upload images if any
      for (int i = 0; i < _images.length; i++) {
        try {
          final dataUrl = await _toDataUrl(_images[i]);
          final imageBody = jsonEncode({
            'imageUrl': dataUrl,
            'isPrimary': i == 0,
            'displayOrder': i,
          });
          await apiClient.post('/api/products/$productId/images', body: imageBody);
        } catch (_) {
          // Non-fatal — product was created, image upload failed
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product listed successfully! 🌿'),
          backgroundColor: AppColors.forestGreen,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List a Product', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_submitting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text(
                'Publish',
                style: TextStyle(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Eco banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco, color: AppColors.forestGreen, size: 26),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'List your eco-friendly or recycled product on the marketplace.',
                      style: TextStyle(color: AppColors.forestGreen, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Photos section ──────────────────────────────────
            _label('Photos'),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add button
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.forestGreen,
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AppColors.forestGreen, size: 28),
                          SizedBox(height: 4),
                          Text('Add photo',
                              style: TextStyle(
                                  color: AppColors.forestGreen,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  // Picked images
                  ..._images.map((img) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 100,
                        height: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(img.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(img)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: AppColors.errorRed),
                          ),
                        ),
                      ),
                      if (_images.indexOf(img) == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Cover',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9)),
                          ),
                        ),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Product Name ────────────────────────────────────
            _label('Product Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco('e.g. Recycled Paper Notebook'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            // ── Description ─────────────────────────────────────
            _label('Description *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: _inputDeco('Describe your product…'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Material Type ───────────────────────────────────
            _label('Material Type *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _materialController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco('e.g. Recycled Plastic, Bamboo…'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Material type is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // ── Price ───────────────────────────────────────────
            _label('Price (LKR) *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco('0.00'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price is required';
                final price = double.tryParse(v.trim());
                if (price == null) return 'Enter a valid number';
                if (price < 0) return 'Price cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Stock (Quantity) ────────────────────────────────
            _label('Available Quantity *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('e.g. 10'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Quantity is required';
                final qty = int.tryParse(v.trim());
                if (qty == null) return 'Enter a valid number';
                if (qty < 0) return 'Quantity cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Category ────────────────────────────────────────
            _label('Category *'),
            const SizedBox(height: 8),
            if (_loadingCategories)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No categories found. Ask your admin to add categories first.',
                  style: TextStyle(color: AppColors.slateGray),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: _inputDeco('Select a category'),
                items: _categories
                    .map((cat) => DropdownMenuItem<String>(
                          value: cat['id']?.toString(),
                          child: Text(cat['name']?.toString() ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) =>
                    v == null ? 'Please select a category' : null,
              ),
            const SizedBox(height: 40),

            // ── Submit ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _submitting ? 'Publishing…' : 'Publish Product',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.darkCharcoal),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.slateGray),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mintGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mintGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.forestGreen, width: 2),
        ),
      );
}
