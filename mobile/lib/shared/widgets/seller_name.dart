import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

/// Blue check shown next to sellers an EcoLoop admin has verified, the same
/// way Facebook Marketplace marks verified profiles.
const Color verifiedBlue = Color(0xFF1877F2);

class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified business',
      child: Icon(
        Icons.verified,
        size: size,
        color: verifiedBlue,
        semanticLabel: 'Verified business',
      ),
    );
  }
}

/// Seller name followed by [VerifiedBadge] when verified. The name shrinks
/// with an ellipsis so the badge always stays visible.
class SellerName extends StatelessWidget {
  final String? name;
  final bool verified;
  final TextStyle? style;
  final double badgeSize;

  const SellerName({
    super.key,
    required this.name,
    required this.verified,
    this.style,
    this.badgeSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            (name?.trim().isNotEmpty ?? false) ? name! : 'Unknown seller',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (verified) ...[
          const SizedBox(width: 4),
          VerifiedBadge(size: badgeSize),
        ],
      ],
    );
  }
}

/// "Seller information" row for details pages: logo, name, verified badge.
class SellerTile extends StatelessWidget {
  final String? name;
  final bool verified;
  final String? logoUrl;

  const SellerTile({
    super.key,
    required this.name,
    required this.verified,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _resolve(logoUrl);
    final initial = (name?.trim().isNotEmpty ?? false) ? name!.trim()[0].toUpperCase() : '?';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.mintGreen,
        foregroundImage: logo == null ? null : NetworkImage(logo),
        child: Text(
          initial,
          style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold),
        ),
      ),
      title: SellerName(
        name: name,
        verified: verified,
        badgeSize: 18,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        verified ? 'Verified business on EcoLoop' : 'Not verified yet',
        style: TextStyle(color: verified ? verifiedBlue : AppColors.slateGray, fontSize: 12),
      ),
    );
  }

  /// Business logos are stored as server paths (/uploads/...); Google profile
  /// photos are full URLs.
  static String? _resolve(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final server = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return url.startsWith('/') ? '$server$url' : '$server/$url';
  }
}
