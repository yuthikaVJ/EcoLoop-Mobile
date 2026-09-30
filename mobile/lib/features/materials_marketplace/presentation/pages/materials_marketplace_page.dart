import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/material_listing_api_service.dart';
import '../../domain/entities/material_listing.dart';
import '../widgets/featured_material_card.dart';
import '../widgets/grid_material_card.dart';
import 'add_material_page.dart';
import 'material_details_page.dart';
import 'my_listings_page.dart';

class MaterialsMarketplacePage extends StatefulWidget {
  const MaterialsMarketplacePage({super.key});

  @override
  State<MaterialsMarketplacePage> createState() => _MaterialsMarketplacePageState();
}

class _MaterialsMarketplacePageState extends State<MaterialsMarketplacePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _api = MaterialListingApiService();
  List<MaterialListing> _allListings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadListings();
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

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = _allListings.isEmpty;
      _error = null;
    });
    try {
      final listings = await _api.getListings();
      if (!mounted) return;
      setState(() {
        _allListings = listings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MaterialListing> _getFilteredListings() {
    final bool isIHaveTab = _tabController.index == 0;
    
    return _allListings.where((listing) {
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
    final listings = _getFilteredListings();
    
    // For demo purposes, we treat the first few as "featured" if there's no search query.
    // If searching, we just show everything in the grid.
    final bool isSearching = _searchQuery.isNotEmpty;
    final featuredListings = isSearching ? <MaterialListing>[] : listings.take(3).toList();
    final gridListings = isSearching ? listings : listings.skip(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: AppColors.forestGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyListingsPage()),
              ).then((_) => _loadListings());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.forestGreen,
          labelColor: AppColors.forestGreen,
          unselectedLabelColor: AppColors.slateGray,
          tabs: const [
            Tab(text: 'I Have'),
            Tab(text: 'I Need'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search materials, categories...',
                prefixIcon: const Icon(Icons.search, color: AppColors.slateGray),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.slateGray),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              ),
            ),
          ),
          
          // Layout Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(color: AppColors.forestGreen),
                    )
                  : _error != null && _allListings.isEmpty
                  ? Center(
                      key: const ValueKey('error'),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slateGray)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadListings, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      key: ValueKey('list_${_tabController.index}_${isSearching ? "search" : "default"}'),
                      color: AppColors.forestGreen,
                      onRefresh: _loadListings,
                      child: listings.isEmpty
                  ? const CustomScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('No materials found.')),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Featured Carousel
                        if (featuredListings.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Text('Featured Listings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                SizedBox(
                                  height: 220,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: featuredListings.length,
                                    itemBuilder: (context, index) {
                                      return TweenAnimationBuilder(
                                        tween: Tween<double>(begin: 0, end: 1),
                                        duration: Duration(milliseconds: 400 + (index * 100)),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, double value, child) {
                                          return Transform.translate(
                                            offset: Offset(50 * (1 - value), 0),
                                            child: Opacity(
                                              opacity: value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: FeaturedMaterialCard(
                                          listing: featuredListings[index],
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => MaterialDetailsPage(
                                                  listing: featuredListings[index],
                                                  heroTag: 'hero_featured_${featuredListings[index].id}',
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
                              padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                              child: Text('All Materials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                          ),
                          
                        // Grid View
                        if (gridListings.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 400 + (index * 50)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, double value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 50 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: GridMaterialCard(
                                      listing: gridListings[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MaterialDetailsPage(
                                              listing: gridListings[index],
                                              heroTag: 'hero_grid_${gridListings[index].id}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                childCount: gridListings.length,
                              ),
                            ),
                          ),
                          
                          // Bottom Padding
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                    ),
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
              pageBuilder: (context, animation, secondaryAnimation) => const AddMaterialPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0); // Slide up from bottom
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeIn),
                );

                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          ).then((posted) {
            if (posted == true) _loadListings();
          });
        },
      ),
    );
  }
}
