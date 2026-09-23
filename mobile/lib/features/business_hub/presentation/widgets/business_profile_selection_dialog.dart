import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/business_profile_session.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business_profile.dart';
import '../pages/business_profile_details_page.dart';

class BusinessProfileSelectionDialog extends StatefulWidget {
  final String? currentUserId;
  final String? currentUserEmail;
  final VoidCallback? onCreateProfile;
  final ValueChanged<BusinessProfile>? onProfileSelected;

  const BusinessProfileSelectionDialog({
    super.key,
    this.currentUserId,
    this.currentUserEmail,
    this.onCreateProfile,
    this.onProfileSelected,
  });

  static Future<BusinessProfile?> show(
    BuildContext context, {
    String? currentUserId,
    String? currentUserEmail,
    VoidCallback? onCreateProfile,
    ValueChanged<BusinessProfile>? onProfileSelected,
  }) async {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    if (isWideScreen) {
      return await showDialog<BusinessProfile>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: BusinessProfileSelectionDialog(
                currentUserId: currentUserId,
                currentUserEmail: currentUserEmail,
                onCreateProfile: onCreateProfile,
                onProfileSelected: onProfileSelected,
              ),
            ),
          ),
        ),
      );
    } else {
      return await showModalBottomSheet<BusinessProfile>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: BusinessProfileSelectionDialog(
            currentUserId: currentUserId,
            currentUserEmail: currentUserEmail,
            onCreateProfile: onCreateProfile,
            onProfileSelected: onProfileSelected,
          ),
        ),
      );
    }
  }

  @override
  State<BusinessProfileSelectionDialog> createState() =>
      _BusinessProfileSelectionDialogState();
}

class _BusinessProfileSelectionDialogState
    extends State<BusinessProfileSelectionDialog> {
  final BusinessRepository _repository = BusinessRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<BusinessProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _repository.getMyBusinessProfiles(
        userId: widget.currentUserId,
        email: widget.currentUserEmail,
      );

      if (mounted) {
        setState(() {
          _profiles = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSelectProfile(BusinessProfile profile) async {
    await BusinessProfileSession().setActiveProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pop(profile);

    if (widget.onProfileSelected != null) {
      widget.onProfileSelected!(profile);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed in as ${profile.businessName}'),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar for bottom sheet drag indicator (mobile only)
        if (MediaQuery.of(context).size.width <= 600)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

        // Header with title and close (X) button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_center,
                  color: AppColors.forestGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Business Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sign in to manage your business',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.slateGray),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Content Area
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Fetching your business profiles...',
                style: TextStyle(color: AppColors.slateGray, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load profiles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slateGray,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchProfiles,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.mintGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_mall_directory_outlined,
                  size: 40,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Business Profiles Found',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You haven\'t created any business profiles under this account yet. Register one to start using the Business Hub.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.slateGray,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget.onCreateProfile != null) {
                    widget.onCreateProfile!();
                  }
                },
                icon: const Icon(Icons.add_business, size: 18),
                label: const Text('Create Business Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _profiles.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return _buildProfileItem(profile);
      },
    );
  }

  Widget _buildProfileItem(BusinessProfile profile) {
    final logoUrl = _repository.apiClient.resolveUrl(profile.logoUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateGray.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onSelectProfile(profile),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Profile Avatar / Picture
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.mintGreen,
                  backgroundImage:
                      logoUrl != null ? NetworkImage(logoUrl) : null,
                  child: logoUrl == null
                      ? Text(
                          profile.businessName.isNotEmpty
                              ? profile.businessName[0].toUpperCase()
                              : 'B',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forestGreen,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Name and Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.businessName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkCharcoal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF1877F2),
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.businessType.isNotEmpty
                                  ? profile.businessType
                                  : 'Business',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slateGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Verification status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: profile.isVerified
                                  ? AppColors.mintGreen
                                  : const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              profile.isVerified ? 'Verified' : 'Unverified',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: profile.isVerified
                                    ? AppColors.forestGreen
                                    : const Color(0xFF856404),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.forestGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
