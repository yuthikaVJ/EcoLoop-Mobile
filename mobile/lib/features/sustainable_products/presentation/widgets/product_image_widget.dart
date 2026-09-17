import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Decodes base64 image bytes in an isolate to avoid blocking the UI thread.
Uint8List _decodeBase64(String base64Str) => base64Decode(base64Str);

/// Smart image widget that handles:
/// - `data:image/...;base64,<data>` URLs (stored by the app)
/// - Regular HTTP URLs (from external sources)
/// - null (shows eco placeholder)
///
/// Base64 decoding is done off the main thread via [compute].
class ProductImageWidget extends StatefulWidget {
  const ProductImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final BoxFit fit;

  @override
  State<ProductImageWidget> createState() => _ProductImageWidgetState();
}

class _ProductImageWidgetState extends State<ProductImageWidget> {
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _bytes;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProductImageWidget old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) {
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Regular network URL — let Image.network handle it
    if (!url.startsWith('data:')) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Check in-memory cache first
    if (_cache.containsKey(url)) {
      if (mounted) setState(() { _bytes = _cache[url]; _loading = false; });
      return;
    }

    // Extract the base64 payload
    final commaIndex = url.indexOf(',');
    if (commaIndex == -1) {
      if (mounted) setState(() { _loading = false; _error = true; });
      return;
    }

    try {
      final base64Str = url.substring(commaIndex + 1);
      // Decode in isolate so the UI stays smooth
      final bytes = await compute(_decodeBase64, base64Str);
      _cache[url] = bytes;
      if (mounted) setState(() { _bytes = bytes; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;

    // No image provided
    if (url == null || url.isEmpty) {
      return _Placeholder();
    }

    // Still decoding
    if (_loading) {
      return _ShimmerBox();
    }

    // Decode failed
    if (_error) {
      return _Placeholder(icon: Icons.image_not_supported_outlined);
    }

    // Base64 decoded successfully
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        width: double.infinity,
        // Cachewidth reduces memory pressure
        cacheWidth: 400,
        gaplessPlayback: true,
      );
    }

    // Regular network URL
    return Image.network(
      url,
      fit: widget.fit,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _ShimmerBox();
      },
      errorBuilder: (_, __, ___) => _Placeholder(
        icon: Icons.image_not_supported_outlined,
      ),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: Color.lerp(
          const Color(0xFFE8F5ED),
          const Color(0xFFCFEAD9),
          _anim.value,
        ),
      ),
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.icon = Icons.eco});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mintGreen,
      child: Center(
        child: Icon(icon, size: 40, color: AppColors.forestGreen),
      ),
    );
  }
}

// ── Full card skeleton for loading state ──────────────────────────────────────

class ProductCardSkeleton extends StatefulWidget {
  const ProductCardSkeleton({super.key});

  @override
  State<ProductCardSkeleton> createState() => _ProductCardSkeletonState();
}

class _ProductCardSkeletonState extends State<ProductCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(
          const Color(0xFFE8F5ED),
          const Color(0xFFCFEAD9),
          _anim.value,
        )!;
        final shimmerDark = Color.lerp(
          const Color(0xFFCFEAD9),
          const Color(0xFFB5DFBF),
          _anim.value,
        )!;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Expanded(
                child: Container(color: shimmer),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Price
                    Container(
                      height: 14,
                      width: 70,
                      decoration: BoxDecoration(
                        color: shimmerDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
