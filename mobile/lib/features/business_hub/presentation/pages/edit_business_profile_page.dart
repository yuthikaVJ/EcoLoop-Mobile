import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_validator.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business_profile.dart';

class EditBusinessProfilePage extends StatefulWidget {
  final BusinessProfile profile;
  final String? currentUserId;

  const EditBusinessProfilePage({
    super.key,
    required this.profile,
    this.currentUserId,
  });

  @override
  State<EditBusinessProfilePage> createState() => _EditBusinessProfilePageState();
}

class _EditBusinessProfilePageState extends State<EditBusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = BusinessRepository();
  final _imagePicker = ImagePicker();

  late BusinessProfile _currentProfile;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;

  final List<String> _businessTypes = [
    'Recycling Company',
    'Sustainable Product Business',
    'Waste Collection & Logistics',
    'Eco Manufacturer',
    'Circular Materials Supplier',
    'Other',
  ];

  String? _selectedBusinessType;
  bool _isSaving = false;
  bool _isUploadingProfilePic = false;
  bool _isUploadingCoverPhoto = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;

    _nameController = TextEditingController(text: _currentProfile.businessName);
    _bioController = TextEditingController(text: _currentProfile.bio ?? '');
    _descriptionController =
        TextEditingController(text: _currentProfile.description ?? '');
    _emailController = TextEditingController(text: _currentProfile.email);
    _phoneController = TextEditingController(text: _currentProfile.phone);
    _addressController = TextEditingController(text: _currentProfile.address);
    _websiteController =
        TextEditingController(text: _currentProfile.websiteUrl ?? '');

    if (_businessTypes.contains(_currentProfile.businessType)) {
      _selectedBusinessType = _currentProfile.businessType;
    } else {
      _selectedBusinessType = _businessTypes.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(String imageType) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

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
          _isUploadingCoverPhoto = true;
        } else {
          _isUploadingProfilePic = true;
        }
      });

      final effectiveUserId = widget.currentUserId ?? _currentProfile.userId;
      final updated = await _repository.uploadBusinessImage(
        _currentProfile.id,
        bytes,
        picked.name,
        imageType,
        userId: effectiveUserId,
      );

      if (!mounted) return;
      setState(() {
        _currentProfile = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imageType == 'cover'
                ? 'Cover photo updated successfully!'
                : 'Profile picture updated successfully!',
          ),
          backgroundColor: AppColors.forestGreen,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.message}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCoverPhoto = false;
          _isUploadingProfilePic = false;
        });
      }
    }
  }

  Future<void> _deleteImage(String imageType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(imageType == 'cover'
            ? 'Remove Cover Photo'
            : 'Remove Profile Picture'),
        content: Text(
          'Are you sure you want to remove your business ${imageType == 'cover' ? 'cover photo' : 'profile picture'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      if (imageType == 'cover') {
        _isUploadingCoverPhoto = true;
      } else {
        _isUploadingProfilePic = true;
      }
    });

    try {
      final effectiveUserId = widget.currentUserId ?? _currentProfile.userId;
      final updated = await _repository.deleteBusinessImage(
        _currentProfile.id,
        imageType,
        userId: effectiveUserId,
      );

      if (!mounted) return;
      setState(() {
        _currentProfile = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imageType == 'cover'
                ? 'Cover photo removed.'
                : 'Profile picture removed.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: ${e.message}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingCoverPhoto = false;
          _isUploadingProfilePic = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'businessName': _nameController.text.trim(),
        'businessType': _selectedBusinessType ?? _currentProfile.businessType,
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'websiteUrl': _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        'logoUrl': _currentProfile.logoUrl,
        'coverPhotoUrl': _currentProfile.coverPhotoUrl,
      };

      final effectiveUserId = widget.currentUserId ?? _currentProfile.userId;
      final updated = await _repository.updateBusinessProfile(
        _currentProfile.id,
        payload,
        userId: effectiveUserId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated successfully!'),
          backgroundColor: AppColors.forestGreen,
        ),
      );
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: ${e.message}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _repository.apiClient.resolveUrl(_currentProfile.coverPhotoUrl);
    final logoUrl = _repository.apiClient.resolveUrl(_currentProfile.logoUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Profile'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: AppColors.forestGreen),
            label: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.errorRed.withOpacity(0.4),
                        ),
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

                  // Visual Media Section (Cover + Profile Picture)
                  const Text(
                    'Profile Media',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cover Photo Preview & Controls
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.mintGreen,
                          image: coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(coverUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: coverUrl == null
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
                                      'No cover photo set',
                                      style: TextStyle(
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                      if (_isUploadingCoverPhoto)
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black38,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Row(
                          children: [
                            if (_currentProfile.coverPhotoUrl != null &&
                                _currentProfile.coverPhotoUrl!.isNotEmpty)
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.errorRed,
                                ),
                                icon: const Icon(Icons.delete_outline, size: 20),
                                tooltip: 'Remove Cover',
                                onPressed: _isUploadingCoverPhoto
                                    ? null
                                    : () => _deleteImage('cover'),
                              ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.darkCharcoal,
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: _isUploadingCoverPhoto
                                  ? null
                                  : () => _pickAndUploadImage('cover'),
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: Text(
                                _currentProfile.coverPhotoUrl != null
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
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.mintGreen,
                            backgroundImage:
                                logoUrl != null ? NetworkImage(logoUrl) : null,
                            child: logoUrl == null
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'B',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forestGreen,
                                    ),
                                  )
                                : null,
                          ),
                          if (_isUploadingProfilePic)
                            const Positioned.fill(
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.black38,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                              'JPG or PNG. Less than 5 MB.',
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
                                  onPressed: _isUploadingProfilePic
                                      ? null
                                      : () => _pickAndUploadImage('profile'),
                                  icon: const Icon(Icons.upload, size: 16),
                                  label: Text(
                                    _currentProfile.logoUrl != null
                                        ? 'Change'
                                        : 'Upload',
                                  ),
                                ),
                                if (_currentProfile.logoUrl != null &&
                                    _currentProfile.logoUrl!.isNotEmpty)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.errorRed,
                                    ),
                                    onPressed: _isUploadingProfilePic
                                        ? null
                                        : () => _deleteImage('profile'),
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

                  // Section: Business Information
                  const Text(
                    'Basic Information',
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
                    value: _selectedBusinessType,
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

                  // Bio / About field
                  TextFormField(
                    controller: _bioController,
                    maxLength: 500,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Short Bio / Catchphrase',
                      hintText:
                          'A brief one-sentence or two-sentence description displayed under your business name.',
                      prefixIcon: Icon(Icons.format_quote_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Full Description',
                      hintText:
                          'Detailed information about your operations, recycling capacity, sustainability missions, etc.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Contact & Location
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
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Business address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Website URL (Optional)',
                      hintText: 'https://example.com',
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
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
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
                                Text('Saving Changes...'),
                              ],
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
