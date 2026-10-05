import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/materials_marketplace/presentation/pages/materials_marketplace_page.dart';
import '../../features/sustainable_products/sustainable_product_marketplace_page.dart';
import '../../core/theme/app_theme.dart';

/// Combined marketplace with a pill-chip switcher at the top.
class MarketplacePage extends ConsumerStatefulWidget {
  const MarketplacePage({super.key, this.initialTabIndex = 0});

  /// 0 = Products, 1 = Materials
  final int initialTabIndex;

  @override
  ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Marketplace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // Pill chips live in the bottom slot of the AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PillChip(
                  label: '🛍  Products',
                  selected: _selected == 0,
                  onTap: () => setState(() => _selected = 0),
                ),
                const SizedBox(width: 10),
                _PillChip(
                  label: '♻️  Materials',
                  selected: _selected == 1,
                  onTap: () => setState(() => _selected = 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _selected == 0
            ? const SustainableProductMarketplacePage(key: ValueKey('products'))
            : const MaterialsMarketplacePage(key: ValueKey('materials')),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.forestGreen : AppColors.mintGreen,
          borderRadius: BorderRadius.circular(50),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.forestGreen,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
