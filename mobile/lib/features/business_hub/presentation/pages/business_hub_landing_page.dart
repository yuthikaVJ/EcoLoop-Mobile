import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/business_profile_session.dart';
import '../../domain/entities/business_profile.dart';
import '../widgets/business_profile_selection_dialog.dart';
import 'business_profile_details_page.dart';
import 'create_business_profile_page.dart';

const String defaultCurrentUserId = '11111111-1111-1111-1111-111111111111';

class BusinessHubLandingPage extends StatefulWidget {
  final String? currentUserId;
  final String? currentUserEmail;

  const BusinessHubLandingPage({
    super.key,
    this.currentUserId = defaultCurrentUserId,
    this.currentUserEmail,
  });

  @override
  State<BusinessHubLandingPage> createState() => _BusinessHubLandingPageState();
}

class _BusinessHubLandingPageState extends State<BusinessHubLandingPage> {
  @override
  void initState() {
    super.initState();
    // Initialize session from SharedPreferences
    BusinessProfileSession().initialize();
  }

  void _openCreatePage() async {
    final userId = widget.currentUserId ?? defaultCurrentUserId;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateBusinessProfilePage(
          currentUserId: userId,
        ),
      ),
    );
  }

  void _openSignInPopup() {
    final userId = widget.currentUserId ?? defaultCurrentUserId;
    BusinessProfileSelectionDialog.show(
      context,
      currentUserId: userId,
      currentUserEmail: widget.currentUserEmail,
      onCreateProfile: _openCreatePage,
    );
  }

  void _navigateToActiveProfile(BusinessProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BusinessProfileDetailsPage(
          profile: profile,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BusinessProfile?>(
      valueListenable: BusinessProfileSession().activeProfileNotifier,
      builder: (context, activeProfile, _) {
        if (activeProfile != null) {
          return BusinessProfileDetailsPage(
            profile: activeProfile,
            currentUserId: widget.currentUserId,
            isActiveSession: true,
          );
        }

        return _buildLandingScaffold();
      },
    );
  }

  Widget _buildLandingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Business Hub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Build a greener tomorrow with your business',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.slateGray,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ValueListenableBuilder<BusinessProfile?>(
              valueListenable: BusinessProfileSession().activeProfileNotifier,
              builder: (context, activeProfile, _) {
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    if (activeProfile != null) {
                      _navigateToActiveProfile(activeProfile);
                    } else {
                      _openSignInPopup();
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeProfile != null
                            ? AppColors.forestGreen
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      activeProfile != null ? Icons.business : Icons.person,
                      color: AppColors.forestGreen,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slateGray.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: AppColors.mintGreen,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.mintGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business_center,
                      size: 34,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Description
                  const Text(
                    'Join EcoLoop Business Hub',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Register your business profile to start buying and selling recyclable materials, listing sustainable products, and requesting official eROC verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.slateGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature Benefits
                  _buildFeatureBenefit(
                    icon: Icons.recycling,
                    title: 'Circular Marketplace Access',
                    subtitle: 'Post materials you have and find what you need',
                  ),
                  const SizedBox(height: 14),
                  _buildFeatureBenefit(
                    icon: Icons.store_mall_directory,
                    title: 'Sustainable Product Store',
                    subtitle:
                        'Sell eco-friendly finished goods directly to consumers',
                  ),
                  const SizedBox(height: 14),
                  _buildFeatureBenefit(
                    icon: Icons.verified,
                    title: 'eROC Business Verification',
                    subtitle:
                        'Get certified by Super Admins and earn the verified badge',
                  ),
                  const SizedBox(height: 28),

                  // Button 1: Create Business Profile
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openCreatePage,
                      icon: const Icon(Icons.business_center, size: 20),
                      label: const Text(
                        'Create Business Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button 2: Sign into Business Profile
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _openSignInPopup,
                      icon: const Icon(
                        Icons.switch_account_outlined,
                        color: AppColors.forestGreen,
                        size: 20,
                      ),
                      label: const Text(
                        'Sign into Business Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.forestGreen,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBenefit({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.mintGreen),
          ),
          child: Icon(icon, size: 20, color: AppColors.forestGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
