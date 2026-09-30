import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/material_listing_api_service.dart';
import '../../domain/entities/material_listing.dart';
import '../widgets/my_listing_card.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = MaterialListingApiService();

  List<MaterialListing> _activeListings = [];
  List<MaterialListing> _completedListings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _error = null);
    try {
      final listings = await _api.getMyListings();
      if (!mounted) return;
      setState(() {
        _activeListings = listings.where((l) => l.status == 0).toList();
        _completedListings = listings.where((l) => l.status == 1).toList();
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

  Future<void> _changeStatus(MaterialListing listing, int status, String successMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.changeStatus(listing.id, status);
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      await _loadListings();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update listing: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _deleteListing(MaterialListing listing, bool isActive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _changeStatus(listing, 2, 'Listing deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAsSold(MaterialListing listing) {
    _changeStatus(listing, 1, 'Listing marked as completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
          : _error != null
          ? Center(
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
          : TabBarView(
        controller: _tabController,
        children: [
          // Active Tab
          RefreshIndicator(
            color: AppColors.forestGreen,
            onRefresh: _loadListings,
            child: _activeListings.isEmpty
              ? _buildEmptyState('You have no active listings.')
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _activeListings.length,
                  itemBuilder: (context, index) {
                    return MyListingCard(
                      listing: _activeListings[index],
                      isActive: true,
                      onEdit: () {
                        // TODO: Navigate to Edit screen
                      },
                      onDelete: () => _deleteListing(_activeListings[index], true),
                      onMarkSold: () => _markAsSold(_activeListings[index]),
                    );
                  },
                ),
          ),
                
          // Completed Tab
          RefreshIndicator(
            color: AppColors.forestGreen,
            onRefresh: _loadListings,
            child: _completedListings.isEmpty
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
                      onDelete: () => _deleteListing(_completedListings[index], false),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyMessage(message),
        ),
      ],
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.slateGray.withOpacity(0.5)),
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
