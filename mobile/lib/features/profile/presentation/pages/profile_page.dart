import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/business_profile.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _industryController;
  late TextEditingController _descController;
  
  bool _isEditing = false;
  BusinessProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _industryController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _industryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _populateControllers(BusinessProfile profile) {
    if (_currentProfile?.id != profile.id || !_isEditing) {
      _currentProfile = profile;
      _nameController.text = profile.businessName;
      _phoneController.text = profile.phoneNumber ?? '';
      _addressController.text = profile.address ?? '';
      _industryController.text = profile.industryType ?? '';
      _descController.text = profile.description ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _currentProfile != null) {
      final updatedProfile = BusinessProfile(
        id: _currentProfile!.id,
        businessName: _nameController.text,
        email: _currentProfile!.email,
        logoUrl: _currentProfile!.logoUrl,
        createdAt: _currentProfile!.createdAt,
        isVerified: _currentProfile!.isVerified,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        industryType: _industryController.text,
        description: _descController.text,
      );

      await ref.read(profileNotifierProvider.notifier).updateProfile(updatedProfile);
      
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          profileState.maybeWhen(
            data: (profile) => IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _populateControllers(profile); // Reset form
                  }
                });
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          _populateControllers(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profile.logoUrl != null
                              ? NetworkImage(profile.logoUrl!)
                              : null,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: profile.logoUrl == null
                              ? Icon(Icons.business, size: 50, color: theme.colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.email ?? 'No email',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (profile.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Chip(
                              label: const Text('Verified Business'),
                              backgroundColor: Colors.green.withOpacity(0.1),
                              labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              avatar: const Icon(Icons.verified, color: Colors.green, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Business Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Business Name',
                    icon: Icons.store,
                    enabled: _isEditing,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _industryController,
                    label: 'Industry Type',
                    icon: Icons.category,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descController,
                    label: 'Description',
                    icon: Icons.description,
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  const Text('Contact Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    enabled: _isEditing,
                  ),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _saveProfile,
                          child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load profile: $err'),
              TextButton(
                onPressed: () {
                  ref.invalidate(profileNotifierProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
      ),
    );
  }
}
