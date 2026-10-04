import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/business_profile_session.dart';
import '../../domain/entities/business_profile.dart';
import '../providers/business_hub_providers.dart';

/// The business the user is currently acting as, if it may post (owned and
/// verified). Used to preselect [PostAsSelector], like Facebook Pages.
String? defaultPostAsBusinessId() {
  final active = BusinessProfileSession().currentProfile;
  if (active == null || !active.isVerified) return null;
  return active.userId == AppConfig.currentBusinessId ? active.id : null;
}

/// "Posting as" picker for new listings and products: the personal account
/// or one of the user's verified Business Hub profiles. `null` means personal.
/// Renders nothing for users who own no business.
class PostAsSelector extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const PostAsSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businesses = ref.watch(myBusinessProfilesProvider).value ?? const [];
    if (businesses.isEmpty) return const SizedBox.shrink();

    final verified = businesses.where((b) => b.isVerified).toList();
    final pending = businesses.where((b) => !b.isVerified).toList();
    final personalName =
        ref.watch(profileNotifierProvider).value?.businessName ?? 'Me';

    // A preselected business that is no longer verified falls back to personal.
    final effective =
        verified.any((b) => b.id == value) ? value : null;
    if (effective != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(null));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mintGreen, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posting as',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.darkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: effective,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: _option(Icons.person, '$personalName (personal)'),
              ),
              for (final business in verified)
                DropdownMenuItem<String?>(
                  value: business.id,
                  child: _option(Icons.verified, business.businessName,
                      color: AppColors.forestGreen),
                ),
            ],
            onChanged: onChanged,
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _pendingMessage(pending),
              style: const TextStyle(fontSize: 12, color: AppColors.slateGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _option(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.slateGray),
        const SizedBox(width: 8),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  static String _pendingMessage(List<BusinessProfile> pending) {
    final names = pending.map((b) => b.businessName).join(', ');
    return '$names can be used after an admin verifies '
        '${pending.length == 1 ? 'it' : 'them'}.';
  }
}
