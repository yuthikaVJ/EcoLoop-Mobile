import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../business_hub/data/business_profile_session.dart';
import '../../../business_hub/domain/entities/business_profile.dart';
import '../../../business_hub/presentation/pages/business_hub_landing_page.dart';
import '../../../business_hub/presentation/pages/create_business_profile_page.dart';
import '../../../business_hub/presentation/providers/business_hub_providers.dart';
import '../../domain/entities/account_profile.dart';
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

  bool _isEditing = false;
  AccountProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populateControllers(AccountProfile profile) {
    if (_currentProfile?.id != profile.id || !_isEditing) {
      _currentProfile = profile;
      _nameController.text = profile.businessName;
      _phoneController.text = profile.phoneNumber ?? '';
      _addressController.text = profile.address ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _currentProfile != null) {
      final updatedProfile = AccountProfile(
        id: _currentProfile!.id,
        businessName: _nameController.text.trim(),
        email: _currentProfile!.email,
        logoUrl: _currentProfile!.logoUrl,
        createdAt: _currentProfile!.createdAt,
        isVerified: _currentProfile!.isVerified,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
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

  Future<void> _openCreateBusiness(String userId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateBusinessProfilePage(currentUserId: userId),
      ),
    );
    ref.invalidate(myBusinessProfilesProvider);
  }

  Future<void> _openBusinessHub(String userId, {BusinessProfile? switchTo}) async {
    if (switchTo != null) {
      await BusinessProfileSession().setActiveProfile(switchTo);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessHubLandingPage(currentUserId: userId),
      ),
    );
    ref.invalidate(myBusinessProfilesProvider);
  }

  Future<void> _signOut() async {
    await BusinessProfileSession().clearActiveProfile();
    ref.read(authNotifierProvider.notifier).signOut();
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
            onPressed: _signOut,
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
                              ? Icon(Icons.person, size: 50, color: theme.colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.businessName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email ?? 'No email',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Mobile Number',
                    icon: Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      return RegExp(r'^\d{10}$').hasMatch(value)
                          ? null
                          : 'Mobile number must be exactly 10 digits';
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    enabled: _isEditing,
                    maxLines: 2,
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
                  const SizedBox(height: 32),
                  const Text('Business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBusinessSection(profile.id),
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

  /// "Request Business Verification" until the account owns a business
  /// profile, then a list of its businesses and a "Business Hub" button.
  Widget _buildBusinessSection(String userId) {
    final businesses = ref.watch(myBusinessProfilesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mintGreen, width: 1.5),
      ),
      child: businesses.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Column(
          children: [
            const Text(
              'Could not load your businesses.',
              style: TextStyle(color: AppColors.slateGray),
            ),
            const SizedBox(height: 4),
            Text(
              err is ApiException && err.statusCode == 404
                  ? 'The server does not have the Business Hub yet. Restart the backend with the latest code.'
                  : err is ApiException
                      ? err.message
                      : 'Check your connection to the server.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
            ),
            TextButton(
              onPressed: () => ref.invalidate(myBusinessProfilesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (list) => list.isEmpty
            ? _buildNoBusiness(userId)
            : _buildBusinessList(userId, list),
      ),
    );
  }

  Widget _buildNoBusiness(String userId) {
    return Column(
      children: [
        const Icon(Icons.business_center, size: 40, color: AppColors.forestGreen),
        const SizedBox(height: 12),
        const Text(
          'Own a business?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
        ),
        const SizedBox(height: 6),
        const Text(
          'Register your business and request eROC verification to buy and sell on the EcoLoop marketplace.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.slateGray, height: 1.4),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _openCreateBusiness(userId),
            icon: const Icon(Icons.verified_outlined),
            label: const Text(
              'Request Business Verification',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessList(String userId, List<BusinessProfile> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final business in list)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.mintGreen,
              backgroundImage: business.logoUrl != null
                  ? NetworkImage(
                      ref.read(businessRepositoryProvider).apiClient.resolveUrl(business.logoUrl)!,
                    )
                  : null,
              child: business.logoUrl == null
                  ? const Icon(Icons.business, color: AppColors.forestGreen)
                  : null,
            ),
            title: Text(
              business.businessName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(business.businessType),
            trailing: _buildStatusChip(business),
            onTap: () => _openBusinessHub(userId, switchTo: business),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _openBusinessHub(userId),
            icon: const Icon(Icons.storefront),
            label: const Text(
              'Business Hub',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BusinessProfile business) {
    final color = business.isVerified
        ? AppColors.forestGreen
        : business.isRejected
            ? AppColors.errorRed
            : const Color(0xFF856404);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        business.isVerified ? 'Verified' : business.isRejected ? 'Rejected' : 'Pending',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
