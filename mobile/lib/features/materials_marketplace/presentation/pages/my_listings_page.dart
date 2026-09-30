import '../../../transactions_delivery/data/services/component4_api_service.dart';
import 'add_material_page.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../widgets/my_listing_card.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _api = Component4ApiService();
  List<MaterialListing> _activeListings = [];
  List<MaterialListing> _completedListings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// [showSpinner] is false for pull-to-refresh, which shows its own indicator
  /// and keeps the current list on screen while reloading.
  Future<void> _load({bool showSpinner = true}) async {
    setState(() {
      _loading = showSpinner;
      _error = null;
    });
    try {
      final lists = await Future.wait([
        _api.getMaterialListings(
          businessId: Component4Config.currentBusinessId,
        ),
        _api.getMaterialListings(
          businessId: Component4Config.currentBusinessId,
          status: 1,
        ),
      ]);
      if (mounted) {
        setState(() {
          _activeListings = lists[0];
          _completedListings = lists[1];
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(MaterialListing listing, int status) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await _api.changeListingStatus(listing.id, status);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _deleteListing(MaterialListing listing, bool isActive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _changeStatus(listing, 2);
  }

  Future<void> _edit(MaterialListing listing) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddMaterialPage(listing: listing)),
    );
    if (saved == true && mounted) await _load();
  }

  void _markAsSold(MaterialListing listing) => _changeStatus(listing, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Listings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.forestGreen,
          labelColor: AppColors.forestGreen,
          unselectedLabelColor: AppColors.slateGray,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Active Tab
                _refreshable(
                  _activeListings.isEmpty
                      ? _buildEmptyState('You have no active listings.')
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _activeListings.length,
                          itemBuilder: (context, index) {
                            return MyListingCard(
                              listing: _activeListings[index],
                              isActive: true,
                              onEdit: () => _edit(_activeListings[index]),
                              onDelete: () =>
                                  _deleteListing(_activeListings[index], true),
                              onMarkSold: () =>
                                  _markAsSold(_activeListings[index]),
                            );
                          },
                        ),
                ),

                // Completed Tab
                _refreshable(
                  _completedListings.isEmpty
                      ? _buildEmptyState('You have no completed listings.')
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _completedListings.length,
                          itemBuilder: (context, index) {
                            return MyListingCard(
                              listing: _completedListings[index],
                              isActive: false,
                              onEdit: () {},
                              onDelete: () => _deleteListing(
                                _completedListings[index],
                                false,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _refreshable(Widget child) => RefreshIndicator(
    color: AppColors.forestGreen,
    onRefresh: () => _load(showSpinner: false),
    child: child,
  );

  // Scrollable so pull-to-refresh also works when a tab is empty.
  Widget _buildEmptyState(String message) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyContent(message),
        ),
      ],
    );
  }

  Widget _buildEmptyContent(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.slateGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.slateGray, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
