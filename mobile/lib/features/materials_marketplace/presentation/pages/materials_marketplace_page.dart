import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../providers/material_listings_provider.dart';
import '../widgets/featured_material_card.dart';
import '../widgets/grid_material_card.dart';
import 'add_material_page.dart';
import 'material_details_page.dart';
import 'my_listings_page.dart';

class MaterialsMarketplacePage extends ConsumerStatefulWidget {
  const MaterialsMarketplacePage({super.key});

  @override
  ConsumerState<MaterialsMarketplacePage> createState() => _MaterialsMarketplacePageState();
}

class _MaterialsMarketplacePageState extends ConsumerState<MaterialsMarketplacePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Clear search when switching tabs for better UX
        setState(() {
          _searchController.clear();
          _searchQuery = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MaterialListing> _getFilteredListings(List<MaterialListing> allListings) {
    final bool isIHaveTab = _tabController.index == 0;
    
    return allListings.where((listing) {
      // 1. Filter by active tab
      if (listing.isIHave != isIHaveTab) return false;
      
      // 2. Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = listing.title.toLowerCase().contains(query);
        final matchCategory = listing.category.toLowerCase().contains(query);
        return matchTitle || matchCategory;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsyncValue = ref.watch(activeListingsNotifierProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Top row: I Have / I Need pills + My Listings icon ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                // Pill chips
                _IHaveNeedChip(
                  label: 'I Have',
                  selected: _tabController.index == 0,
                  onTap: () => setState(() => _tabController.index = 0),
                ),
                const SizedBox(width: 8),
                _IHaveNeedChip(
                  label: 'I Need',
                  selected: _tabController.index == 1,
                  onTap: () => setState(() => _tabController.index = 1),
                ),
                const Spacer(),
                // My Listings shortcut
                IconButton(
                  icon: const Icon(Icons.list_alt,
                      color: AppColors.forestGreen),
                  tooltip: 'My Listings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MyListingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search materials, categories...',
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.slateGray),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.slateGray),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
              ),
            ),
          ),

          // ── Listings content ────────────────────────────────────────────
          Expanded(
            child: listingsAsyncValue.when(
              skipLoadingOnReload: false,
              skipLoadingOnRefresh: false,
              loading: () => _MaterialsSkeletonView(),
              error: (err, stack) => Center(
                child: Text('Error loading materials: $err',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (allListings) {
                final listings = _getFilteredListings(allListings);
                final bool isSearching = _searchQuery.isNotEmpty;
                final featuredListings =
                    isSearching ? <MaterialListing>[] : listings.take(3).toList();
                final gridListings =
                    isSearching ? listings : listings.skip(3).toList();

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: listings.isEmpty
                      ? const Center(
                          key: ValueKey('empty'),
                          child: Text('No materials found.'),
                        )
                      : RefreshIndicator(
                          color: AppColors.forestGreen,
                          onRefresh: () async {
                            ref.invalidate(activeListingsNotifierProvider);
                          },
                          child: CustomScrollView(
                            key: ValueKey(
                                'list_${_tabController.index}_${isSearching ? "search" : "default"}'),
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              // Featured Carousel
                            if (featuredListings.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      child: Text('Featured Listings',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                    ),
                                    SizedBox(
                                      height: 220,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        itemCount: featuredListings.length,
                                        itemBuilder: (context, index) {
                                          return TweenAnimationBuilder(
                                            tween: Tween<double>(
                                                begin: 0, end: 1),
                                            duration: Duration(
                                                milliseconds:
                                                    400 + (index * 100)),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, double value,
                                                child) {
                                              return Transform.translate(
                                                offset: Offset(
                                                    50 * (1 - value), 0),
                                                child: Opacity(
                                                    opacity: value,
                                                    child: child),
                                              );
                                            },
                                            child: FeaturedMaterialCard(
                                              listing:
                                                  featuredListings[index],
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        MaterialDetailsPage(
                                                      listing: featuredListings[
                                                          index],
                                                      heroTag:
                                                          'hero_featured_${featuredListings[index].id}',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),

                            // Grid View Header
                            if (gridListings.isNotEmpty)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      16.0, 8.0, 16.0, 16.0),
                                  child: Text('All Materials',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ),
                              ),

                            // Grid View
                            if (gridListings.isNotEmpty)
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.8,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return TweenAnimationBuilder(
                                        tween: Tween<double>(
                                            begin: 0, end: 1),
                                        duration: Duration(
                                            milliseconds:
                                                400 + (index * 50)),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, double value,
                                            child) {
                                          return Transform.translate(
                                            offset:
                                                Offset(0, 50 * (1 - value)),
                                            child: Opacity(
                                                opacity: value,
                                                child: child),
                                          );
                                        },
                                        child: RepaintBoundary(
                                          child: GridMaterialCard(
                                            listing: gridListings[index],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      MaterialDetailsPage(
                                                    listing:
                                                        gridListings[index],
                                                    heroTag:
                                                        'hero_grid_${gridListings[index].id}',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    childCount: gridListings.length,
                                  ),
                                ),
                              ),

                            const SliverToBoxAdapter(
                                child: SizedBox(height: 80)),
                          ],
                        ),
                      ),
                    );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.forestGreen,
        child: const Icon(Icons.add, color: AppColors.white),
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddMaterialPage(
                      initialIsIHave: _tabController.index == 0),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                final tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                final offsetAnimation = animation.drive(tween);
                final fadeAnimation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeIn),
                );
                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                      opacity: fadeAnimation, child: child),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
      ),
    );
  }
}

// ── Skeleton loading view ─────────────────────────────────────────────────────

class _MaterialsSkeletonView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Featured skeleton row
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _SkeletonBox(width: 160, height: 18),
              ),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: _FeaturedCardSkeleton(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Grid header skeleton
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _SkeletonBox(width: 120, height: 18),
          ),
        ),
        // Grid skeleton
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => const _GridCardSkeleton(),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({required this.width, required this.height, this.borderRadius = 6});
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFE8F5ED), const Color(0xFFCFEAD9), _anim.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _FeaturedCardSkeleton extends StatelessWidget {
  const _FeaturedCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateGray.withValues(alpha: 0.10),
            blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          const Expanded(child: _SkeletonBox(width: 260, height: 140, borderRadius: 0)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonBox(width: 80, height: 10),
                SizedBox(height: 6),
                _SkeletonBox(width: 160, height: 14),
                SizedBox(height: 8),
                _SkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCardSkeleton extends StatelessWidget {
  const _GridCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mintGreen, width: 1),
      ),
      child: Column(
        children: [
          const Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              child: _SkeletonBox(width: double.infinity, height: double.infinity),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SkeletonBox(width: 60, height: 9),
                  SizedBox(height: 4),
                  _SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 4),
                  _SkeletonBox(width: 80, height: 12),
                  Spacer(),
                  _SkeletonBox(width: 50, height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _IHaveNeedChip extends StatelessWidget {
  const _IHaveNeedChip({
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
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.forestGreen : AppColors.mintGreen,
          borderRadius: BorderRadius.circular(50),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        AppColors.forestGreen.withValues(alpha: 0.30),
                    blurRadius: 6,
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
