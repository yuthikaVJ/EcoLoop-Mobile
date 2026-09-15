import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/business_profile.dart';

class BusinessProfileDetailsPage extends StatelessWidget {
  final BusinessProfile profile;
  final bool isNewlyCreated;

  const BusinessProfileDetailsPage({
    super.key,
    required this.profile,
    this.isNewlyCreated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share business profile coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isNewlyCreated) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
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
          ],

          // Header Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.mintGreen,
                        backgroundImage: profile.logoUrl != null &&
                                profile.logoUrl!.isNotEmpty
                            ? NetworkImage(profile.logoUrl!)
                            : null,
                        child: profile.logoUrl == null ||
                                profile.logoUrl!.isEmpty
                            ? Text(
                                profile.businessName.isNotEmpty
                                    ? profile.businessName[0].toUpperCase()
                                    : 'B',
                                style: const TextStyle(
                                  fontSize: 28,
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
                            Text(
                              profile.businessName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                            const SizedBox(height: 6),
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
                                profile.businessType,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verification Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.slateGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: profile.isVerified
                              ? AppColors.mintGreen
                              : const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: profile.isVerified
                                ? AppColors.ecoGreen
                                : const Color(0xFFFFEEBA),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              profile.isVerified
                                  ? Icons.verified
                                  : Icons.hourglass_empty_rounded,
                              size: 16,
                              color: profile.isVerified
                                  ? AppColors.forestGreen
                                  : const Color(0xFF856404),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profile.isVerified ? 'Verified' : profile.status,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: profile.isVerified
                                  ? AppColors.forestGreen
                                  : const Color(0xFF856404),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Business Information Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registration & Contact',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Registration Number (eROC/ROC)',
                    value: profile.registrationNumber,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Business Email',
                    value: profile.email,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact Phone',
                    value: profile.phone,
                  ),
                  const Divider(height: 20),
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address / Operating Base',
                    value: profile.address,
                  ),
                  if (profile.websiteUrl != null &&
                      profile.websiteUrl!.isNotEmpty) ...[
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: Icons.language_outlined,
                      label: 'Website',
                      value: profile.websiteUrl!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          if (profile.description != null &&
              profile.description!.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About the Business',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profile.description!,
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
            const SizedBox(height: 16),
          ],

          // Next Steps Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mintGreen, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.ecoGreen,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Step: Verification Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your business profile is created and ready. In the next phase, you will be able to upload business verification documents for Super Admin eROC review to earn your Verified badge.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slateGray.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Action Button
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Business Hub'),
          ),
          const SizedBox(height: 20),
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
              Text(
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
