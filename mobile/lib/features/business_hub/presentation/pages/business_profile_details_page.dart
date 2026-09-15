import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business_profile.dart';
import 'edit_business_profile_page.dart';

class BusinessProfileDetailsPage extends StatefulWidget {
  final BusinessProfile profile;
  final bool isNewlyCreated;
  final String? currentUserId;

  const BusinessProfileDetailsPage({
    super.key,
    required this.profile,
    this.isNewlyCreated = false,
    this.currentUserId,
  });

  @override
  State<BusinessProfileDetailsPage> createState() =>
      _BusinessProfileDetailsPageState();
}

class _BusinessProfileDetailsPageState
    extends State<BusinessProfileDetailsPage> {
  late BusinessProfile _profile;
  final _repository = BusinessRepository();
  final _imagePicker = ImagePicker();

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  bool get _isOwner {
    if (widget.currentUserId == null || _profile.userId == null) return true;
    return widget.currentUserId == _profile.userId;
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<BusinessProfile>(
      MaterialPageRoute(
        builder: (context) => EditBusinessProfilePage(
          profile: _profile,
          currentUserId: widget.currentUserId,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _profile = updated;
      });
    }
  }

  Future<void> _pickAndUploadPhoto(String imageType) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image must be smaller than 5 MB.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final effectiveUserId = widget.currentUserId ?? _profile.userId;
      final updated = await _repository.uploadBusinessImage(
        _profile.id,
        bytes,
        picked.name,
        imageType,
        userId: effectiveUserId,
      );

      if (!mounted) return;
      setState(() {
        _profile = updated;
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
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deletePhoto(String imageType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(imageType == 'cover'
            ? 'Remove Cover Photo'
            : 'Remove Profile Picture'),
        content: Text(
          'Are you sure you want to remove this ${imageType == 'cover' ? 'cover photo' : 'profile picture'}?',
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
      _isUploading = true;
    });

    try {
      final effectiveUserId = widget.currentUserId ?? _profile.userId;
      final updated = await _repository.deleteBusinessImage(
        _profile.id,
        imageType,
        userId: effectiveUserId,
      );

      if (!mounted) return;
      setState(() {
        _profile = updated;
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
          content: Text('Failed: ${e.message}'),
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
          _isUploading = false;
        });
      }
    }
  }

  void _showCoverPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_profile.coverPhotoUrl != null
                  ? 'Change Cover Photo'
                  : 'Upload Cover Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadPhoto('cover');
              },
            ),
            if (_profile.coverPhotoUrl != null &&
                _profile.coverPhotoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                title: const Text(
                  'Remove Cover Photo',
                  style: TextStyle(color: AppColors.errorRed),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _deletePhoto('cover');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showProfilePicOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(_profile.logoUrl != null
                  ? 'Change Profile Picture'
                  : 'Upload Profile Picture'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadPhoto('profile');
              },
            ),
            if (_profile.logoUrl != null && _profile.logoUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                title: const Text(
                  'Remove Profile Picture',
                  style: TextStyle(color: AppColors.errorRed),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _deletePhoto('profile');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _repository.apiClient.resolveUrl(_profile.coverPhotoUrl);
    final logoUrl = _repository.apiClient.resolveUrl(_profile.logoUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _profile.businessName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Profile',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile link for ${_profile.businessName} copied!'),
                ),
              );
            },
          ),
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: _openEditProfile,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: RefreshIndicator(
            onRefresh: () async {
              try {
                final refreshed = await _repository.getBusinessProfile(_profile.id);
                if (refreshed != null && mounted) {
                  setState(() {
                    _profile = refreshed;
                  });
                }
              } catch (_) {}
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (widget.isNewlyCreated) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.ecoGreen),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.forestGreen),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Business profile successfully created! You are now registered on the EcoLoop platform.',
                              style: TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Facebook-Style Header Section (Cover Photo + Profile Picture)
                _buildSocialHeader(coverUrl, logoUrl),

                // Business Name, Bio, Type and Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Business Name + Verified Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _profile.businessName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_profile.isVerified ||
                                    _profile.status.toLowerCase() == 'verified')
                                  const Tooltip(
                                    message: 'Verified Business on EcoLoop',
                                    child: Icon(
                                      Icons.verified,
                                      color: Color(0xFF1877F2), // Facebook/Social Blue
                                      size: 22,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Business Type & Verification Chip Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.offWhite,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.mintGreen),
                            ),
                            child: Text(
                              _profile.businessType,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _profile.isVerified
                                  ? AppColors.mintGreen
                                  : const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _profile.isVerified
                                    ? AppColors.ecoGreen
                                    : const Color(0xFFFFEEBA),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _profile.isVerified
                                      ? Icons.check_circle_outline
                                      : Icons.hourglass_empty_rounded,
                                  size: 14,
                                  color: _profile.isVerified
                                      ? AppColors.forestGreen
                                      : const Color(0xFF856404),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _profile.isVerified
                                      ? 'Verified'
                                      : _profile.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _profile.isVerified
                                        ? AppColors.forestGreen
                                        : const Color(0xFF856404),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bio / About section
                      if (_profile.bio != null && _profile.bio!.isNotEmpty) ...[
                        Text(
                          _profile.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppColors.darkCharcoal.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else if (_isOwner) ...[
                        InkWell(
                          onTap: _openEditProfile,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.offWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.mintGreen,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.forestGreen,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Add bio to introduce your business',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Action Bar (Edit Profile Button & Share)
                      if (_isOwner) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _openEditProfile,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Profile link for ${_profile.businessName} copied to clipboard!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Divider(height: 24),

                      // Business About / Description Card
                      if (_profile.description != null &&
                          _profile.description!.isNotEmpty) ...[
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: AppColors.forestGreen,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'About Business',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkCharcoal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _profile.description!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.darkCharcoal,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Contact & Location Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact & Operational Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                icon: Icons.email_outlined,
                                label: 'Business Email',
                                value: _profile.email,
                              ),
                              const Divider(height: 20),
                              _buildInfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Contact Phone',
                                value: _profile.phone,
                              ),
                              const Divider(height: 20),
                              _buildInfoRow(
                                icon: Icons.location_on_outlined,
                                label: 'Address / Operational Base',
                                value: _profile.address,
                              ),
                              if (_profile.websiteUrl != null &&
                                  _profile.websiteUrl!.isNotEmpty) ...[
                                const Divider(height: 20),
                                _buildInfoRow(
                                  icon: Icons.language_outlined,
                                  label: 'Official Website',
                                  value: _profile.websiteUrl!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Business Registration Information Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Business Registration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildInfoRow(
                                icon: Icons.confirmation_number_outlined,
                                label: 'Registration Number (eROC/ROC)',
                                value: _profile.registrationNumber,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialHeader(String? coverUrl, String? logoUrl) {
    const double bannerHeight = 180;
    const double avatarRadius = 46;

    return SizedBox(
      height: bannerHeight + avatarRadius - 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover Photo Banner
          Container(
            height: bannerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: coverUrl == null
                  ? const LinearGradient(
                      colors: [AppColors.forestGreen, AppColors.ecoGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              image: coverUrl != null
                  ? DecorationImage(
                      image: NetworkImage(coverUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: coverUrl == null
                ? Center(
                    child: Icon(
                      Icons.eco,
                      size: 64,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  )
                : null,
          ),

          if (_isUploading)
            Container(
              height: bannerHeight,
              width: double.infinity,
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // Cover Photo Camera Button (for owner)
          if (_isOwner)
            Positioned(
              right: 16,
              bottom: avatarRadius + 4,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.92),
                  foregroundColor: AppColors.darkCharcoal,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: _isUploading ? null : _showCoverPhotoOptions,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: Text(
                  _profile.coverPhotoUrl != null ? 'Edit Cover' : 'Add Cover',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Overlapping Circular Profile Picture
          Positioned(
            left: 20,
            bottom: 0,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4), // White border ring
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: AppColors.mintGreen,
                    backgroundImage:
                        logoUrl != null ? NetworkImage(logoUrl) : null,
                    child: logoUrl == null
                        ? Text(
                            _profile.businessName.isNotEmpty
                                ? _profile.businessName[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forestGreen,
                            ),
                          )
                        : null,
                  ),
                ),

                // Profile Picture Edit Camera Badge
                if (_isOwner)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: InkWell(
                      onTap: _isUploading ? null : _showProfilePicOptions,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.forestGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateGray,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
