import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../providers/material_listings_provider.dart';
import '../widgets/material_list_card.dart';
import 'add_material_page.dart';
import 'material_details_page.dart';
import 'my_listings_page.dart';
import '../../../ai_matching/presentation/matches_page.dart';
import '../../../ai_matching/presentation/matches_providers.dart';

class MaterialsMarketplacePage extends ConsumerStatefulWidget {
  const MaterialsMarketplacePage({super.key});

  @override
  ConsumerState<MaterialsMarketplacePage> createState() =>
      _MaterialsMarketplacePageState();
}

class _MaterialsMarketplacePageState
    extends ConsumerState<MaterialsMarketplacePage>
    with SingleTickerProviderStateMixin {
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

  List<MaterialListing> _getFilteredListings(
    List<MaterialListing> allListings,
  ) {
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

  void _openAddPage() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddMaterialPage(initialIsIHave: _tabController.index == 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
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
                // AI match suggestions
                IconButton(
                  tooltip: 'AI Matches',
                  icon: Badge(
                    isLabelVisible: ref.watch(pendingMatchCountProvider) > 0,
                    label: Text('${ref.watch(pendingMatchCountProvider)}'),
                    child: const Icon(Icons.auto_awesome, color: AppColors.forestGreen),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MatchesPage()),
                  ),
                ),
                // My Listings shortcut
                IconButton(
                  icon: const Icon(
                    Icons.list_alt,
                    color: AppColors.forestGreen,
                  ),
                  tooltip: 'My Listings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyListingsPage()),
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
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search materials, categories...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.slateGray,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.slateGray,
                        ),
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
              loading: () => const _MaterialsSkeletonView(),
              error: (err, stack) => Center(
                child: Text(
                  'Error loading materials: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (allListings) {
                final listings = _getFilteredListings(allListings);
                return RefreshIndicator(
                  color: AppColors.forestGreen,
                  onRefresh: () async {
                    ref.invalidate(activeListingsNotifierProvider);
                  },
                  // One consistent vertical list: fills the page whether there
                  // is 1 listing or 50 (the old "first 3 in a row" layout left
                  // the rest of the page blank when a tab had few items).
                  child: listings.isEmpty
                      ? _EmptyState(
                          isIHave: _tabController.index == 0,
                          searchQuery: _searchQuery,
                          onPost: _openAddPage,
                        )
                      : ListView.separated(
                          key: PageStorageKey(
                            'materials_${_tabController.index}',
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: listings.length + 1,
                          separatorBuilder: (_, index) =>
                              SizedBox(height: index == 0 ? 8 : 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _ListHeader(
                                count: listings.length,
                                searchQuery: _searchQuery,
                              );
                            }
                            final listing = listings[index - 1];
                            final heroTag = 'hero_list_${listing.id}';
                            return _FadeIn(
                              index: index - 1,
                              child: MaterialListCard(
                                listing: listing,
                                heroTag: heroTag,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MaterialDetailsPage(
                                      listing: listing,
                                      heroTag: heroTag,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
        onPressed: _openAddPage,
      ),
    );
  }
}

// ── Skeleton loading view ─────────────────────────────────────────────────────
// Same shape as the real list (header + MaterialListCard rows) so nothing
// jumps when the data arrives.

class _MaterialsSkeletonView extends StatelessWidget {
  const _MaterialsSkeletonView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: 7,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 8 : 12),
      itemBuilder: (_, index) => index == 0
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: _SkeletonBox(width: 90, height: 12),
              ),
            )
          : const _ListCardSkeleton(),
    );
  }
}

class _ListCardSkeleton extends StatelessWidget {
  const _ListCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mintGreen),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(
            width: MaterialListCard.thumbnailSize,
            height: MaterialListCard.thumbnailSize,
            borderRadius: 12,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 64, height: 10),
                SizedBox(height: 8),
                _SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                _SkeletonBox(width: 90, height: 14),
                SizedBox(height: 10),
                _SkeletonBox(width: 150, height: 10),
                SizedBox(height: 6),
                _SkeletonBox(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── List header / empty state / entry animation ──────────────────────────────

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.count, required this.searchQuery});

  final int count;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final noun = count == 1 ? 'listing' : 'listings';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        searchQuery.isEmpty
            ? '$count $noun'
            : '$count $noun for "$searchQuery"',
        style: const TextStyle(
          color: AppColors.slateGray,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isIHave,
    required this.searchQuery,
    required this.onPost,
  });

  final bool isIHave;
  final String searchQuery;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final searching = searchQuery.isNotEmpty;
    final title = searching
        ? 'No results for "$searchQuery"'
        : isIHave
        ? 'No materials available yet'
        : 'No material requests yet';
    final message = searching
        ? 'Try a different name or category.'
        : isIHave
        ? 'Materials that businesses have to offer will appear here.'
        : 'Materials that businesses are looking for will appear here.';
    // Scrollable so pull-to-refresh still works on an empty list.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 96),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: AppColors.mintGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    searching ? Icons.search_off : Icons.inventory_2_outlined,
                    color: AppColors.forestGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.darkCharcoal,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.slateGray),
                ),
                if (!searching) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onPost,
                    icon: const Icon(Icons.add),
                    label: Text(isIHave ? 'Post a material' : 'Post a request'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle staggered fade/slide for list rows (capped so long lists stay quick).
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + 40 * index.clamp(0, 6)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 6,
  });
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
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFE8F5ED),
            const Color(0xFFCFEAD9),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.forestGreen : AppColors.mintGreen,
          borderRadius: BorderRadius.circular(50),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.30),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
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
