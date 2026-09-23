import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_validator.dart';
import '../../data/business_repository.dart';
import 'business_profile_details_page.dart';

class CreateBusinessProfilePage extends StatefulWidget {
  final String? currentUserId;

  const CreateBusinessProfilePage({
    super.key,
    this.currentUserId,
  });

  @override
  State<CreateBusinessProfilePage> createState() =>
      _CreateBusinessProfilePageState();
}

class _CreateBusinessProfilePageState extends State<CreateBusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _businessRepository = BusinessRepository();
  final _imagePicker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _logoUrlController = TextEditingController();

  // Selected Images (Optional)
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  Uint8List? _coverImageBytes;
  String? _coverImageName;

  final List<String> _businessTypes = [
    'Recycling Company',
    'Sustainable Product Business',
    'Waste Collection & Logistics',
    'Eco Manufacturer',
    'Circular Materials Supplier',
    'Other',
  ];

  String? _selectedBusinessType;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedBusinessType = _businessTypes.first;
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted && _profileImageBytes == null) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _regNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String imageType) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // Validate format and size
      final validation = ImageValidator.validateImage(
        fileName: picked.name,
        byteLength: bytes.length,
      );

      if (!validation.isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      setState(() {
        if (imageType == 'cover') {
          _coverImageBytes = bytes;
          _coverImageName = picked.name;
        } else {
          _profileImageBytes = bytes;
          _profileImageName = picked.name;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _removeImage(String imageType) {
    setState(() {
      if (imageType == 'cover') {
        _coverImageBytes = null;
        _coverImageName = null;
      } else {
        _profileImageBytes = null;
        _profileImageName = null;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'businessName': _nameController.text.trim(),
        'businessType': _selectedBusinessType ?? _businessTypes.first,
        'registrationNumber': _regNumberController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'websiteUrl': _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        'logoUrl': _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
        if (widget.currentUserId != null) 'userId': widget.currentUserId,
      };

      var createdProfile = await _businessRepository.createBusinessProfile(
        payload,
        userId: widget.currentUserId,
      );

      final effectiveUserId = widget.currentUserId ?? createdProfile.userId;

      // Upload profile image if user chose one
      if (_profileImageBytes != null) {
        try {
          createdProfile = await _businessRepository.uploadBusinessImage(
            createdProfile.id,
            _profileImageBytes!,
            _profileImageName ?? 'profile.png',
            'profile',
            userId: effectiveUserId,
          );
        } catch (e) {
          debugPrint('Profile image upload failed: $e');
        }
      }

      // Upload cover photo if user chose one
      if (_coverImageBytes != null) {
        try {
          createdProfile = await _businessRepository.uploadBusinessImage(
            createdProfile.id,
            _coverImageBytes!,
            _coverImageName ?? 'cover.png',
            'cover',
            userId: effectiveUserId,
          );
        } catch (e) {
          debugPrint('Cover photo upload failed: $e');
        }
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BusinessProfileDetailsPage(
            profile: createdProfile,
            isNewlyCreated: true,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create profile: ${e.message}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Business Profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Intro banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mintGreen),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      color: AppColors.forestGreen,
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Your Business',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter your official business information to trade circular materials or list sustainable products on EcoLoop.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkCharcoal,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorRed.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.errorRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Section: Profile Media (Optional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Media',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Optional',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cover Image Preview & Controls
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.mintGreen,
                      image: _coverImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_coverImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverImageBytes == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.panorama_outlined,
                                  size: 40,
                                  color: AppColors.forestGreen,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Add Cover Photo (Optional)',
                                  style: TextStyle(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'PNG or JPEG, less than 5 MB',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.slateGray,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Row(
                      children: [
                        if (_coverImageBytes != null)
                          IconButton.filled(
                            key: const ValueKey('remove_cover_button'),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.errorRed,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: 'Remove Cover',
                            onPressed: _isLoading ? null : () => _removeImage('cover'),
                          ),
                        if (_coverImageBytes != null)
                          const SizedBox(width: 8),
                        ElevatedButton.icon(
                          key: const ValueKey('pick_cover_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.darkCharcoal,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: _isLoading ? null : () => _pickImage('cover'),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: Text(
                            _coverImageBytes != null
                                ? 'Change Cover'
                                : 'Add Cover',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Picture Preview & Controls
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.mintGreen,
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                    child: _profileImageBytes == null
                        ? Text(
                            _nameController.text.trim().isNotEmpty
                                ? _nameController.text.trim()[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forestGreen,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Picture',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PNG or JPEG. Less than 5 MB.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slateGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              key: const ValueKey('pick_profile_button'),
                              onPressed: _isLoading
                                  ? null
                                  : () => _pickImage('profile'),
                              icon: const Icon(Icons.upload, size: 16),
                              label: Text(
                                _profileImageBytes != null
                                    ? 'Change'
                                    : 'Upload',
                              ),
                            ),
                            if (_profileImageBytes != null)
                              TextButton.icon(
                                key: const ValueKey('remove_profile_button'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.errorRed,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => _removeImage('profile'),
                                icon: const Icon(Icons.delete_outline,
                                    size: 16),
                                label: const Text('Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Section 1: Business Identity
              const Text(
                'Business Identity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business / Company Name *',
                  hintText: 'e.g. GreenCycle Lanka Pvt Ltd',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _selectedBusinessType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Business Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _businessTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a business type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _regNumberController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number (eROC/ROC) *',
                  hintText: 'e.g. PV-102938 or BR-45920',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                  helperText: 'Used for Super Admin eROC business verification',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business registration number is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Registration number must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section 2: Contact & Location
              const Text(
                'Contact & Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Official Business Email *',
                  hintText: 'info@greencycle.lk',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Contact Phone *',
                  hintText: '0712345678',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final phone = value.trim();
                  if (!RegExp(r'^\d+$').hasMatch(phone)) {
                    return 'Phone number must contain only numbers';
                  }
                  if (phone.length != 10) {
                    return 'Phone number must be exactly 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Business Address / Operational Base *',
                  hintText: '123 Green Industrial Zone, Colombo 05',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business address is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section 3: Online Presence & Details
              const Text(
                'Online Presence & Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'About the Business (Optional)',
                  hintText:
                      'Describe your operations, sustainability focus, recycling capacity or products...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website URL (Optional)',
                  hintText: 'https://www.greencycle.lk',
                  prefixIcon: Icon(Icons.language_outlined),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.trim().startsWith('http://') &&
                        !value.trim().startsWith('https://')) {
                      return 'URL must start with http:// or https://';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _logoUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Logo Image URL (Optional)',
                  hintText: 'https://example.com/logo.png',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.trim().startsWith('http://') &&
                        !value.trim().startsWith('https://')) {
                      return 'URL must start with http:// or https://';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Profile...'),
                          ],
                        )
                      : const Text(
                          'Create Business Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
