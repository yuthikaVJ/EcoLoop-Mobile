import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/business_repository.dart';
import '../../domain/entities/business_profile.dart';
import 'business_profile_details_page.dart';
import 'create_business_profile_page.dart';

class BusinessHubLandingPage extends StatefulWidget {
  const BusinessHubLandingPage({super.key});

  @override
  State<BusinessHubLandingPage> createState() => _BusinessHubLandingPageState();
}

class _BusinessHubLandingPageState extends State<BusinessHubLandingPage> {
  final BusinessRepository _repository = BusinessRepository();
  late Future<List<BusinessProfile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _profilesFuture = _repository.getAllBusinessProfiles();
    });
  }

  Future<void> _refresh() async {
    _loadProfiles();
    await _profilesFuture;
  }

  void _openCreatePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateBusinessProfilePage(),
      ),
    );
    _loadProfiles();
  }

  String _formatErrorMessage(Object? error) {
    if (error == null) return 'An unknown error occurred.';
    final errorStr = error.toString();
    if (errorStr.contains('\n')) {
      return errorStr.split('\n').first.trim();
    }
    return errorStr;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Business Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<BusinessProfile>>(
          future: _profilesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 56,
                        color: AppColors.slateGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to connect to EcoLoop API',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatErrorMessage(snapshot.error),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }


            final profiles = snapshot.data ?? [];

            if (profiles.isEmpty) {
              return _buildEmptyState();
            }

            return _buildProfilesView(profiles);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.slateGray.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.mintGreen, width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(
                  Icons.business_center,
                  size: 36,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 20),
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
              _buildFeatureBenefit(
                icon: Icons.recycling,
                title: 'Circular Marketplace Access',
                subtitle: 'Post I HAVE materials and I NEED requests',
              ),
              const SizedBox(height: 14),
              _buildFeatureBenefit(
                icon: Icons.store_mall_directory,
                title: 'Sustainable Product Store',
                subtitle: 'Sell eco-friendly finished goods directly to consumers',
              ),
              const SizedBox(height: 14),
              _buildFeatureBenefit(
                icon: Icons.verified,
                title: 'eROC Business Verification',
                subtitle: 'Get certified by Super Admins and earn the verified badge',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _openCreatePage,
                  icon: const Icon(Icons.add_business),
                  label: const Text(
                    'Create Business Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilesView(List<BusinessProfile> profiles) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registered Businesses (${profiles.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkCharcoal,
              ),
            ),
            TextButton.icon(
              onPressed: _openCreatePage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Another'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...profiles.map((profile) => _buildProfileCard(profile)),
      ],
    );
  }

  Widget _buildProfileCard(BusinessProfile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BusinessProfileDetailsPage(profile: profile),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.mintGreen,
                    backgroundImage: profile.logoUrl != null &&
                            profile.logoUrl!.isNotEmpty
                        ? NetworkImage(profile.logoUrl!)
                        : null,
                    child: profile.logoUrl == null || profile.logoUrl!.isEmpty
                        ? Text(
                            profile.businessName.isNotEmpty
                                ? profile.businessName[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forestGreen,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.businessName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.businessType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.slateGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: profile.isVerified
                          ? AppColors.mintGreen
                          : const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: profile.isVerified
                            ? AppColors.ecoGreen
                            : const Color(0xFFFFEEBA),
                      ),
                    ),
                    child: Text(
                      profile.isVerified ? 'Verified' : profile.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: profile.isVerified
                            ? AppColors.forestGreen
                            : const Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: AppColors.slateGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reg: ${profile.registrationNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.slateGray,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      profile.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slateGray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.forestGreen,
                  ),
                ],
              ),
            ],
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
