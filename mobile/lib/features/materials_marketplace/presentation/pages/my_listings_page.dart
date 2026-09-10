import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../widgets/my_listing_card.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Using dummy data to simulate the user's listings
  late List<MaterialListing> _activeListings;
  late List<MaterialListing> _completedListings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize dummy data state
    _activeListings = dummyListings.take(4).toList();
    _completedListings = dummyListings.skip(4).take(2).toList();
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
              setState(() {
                if (isActive) {
                  _activeListings.remove(listing);
                } else {
                  _completedListings.remove(listing);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAsSold(MaterialListing listing) {
    setState(() {
      _activeListings.remove(listing);
      _completedListings.insert(0, listing);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing marked as completed')),
    );
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Tab
          _activeListings.isEmpty
              ? _buildEmptyState('You have no active listings.')
              : ListView.builder(
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
                
          // Completed Tab
          _completedListings.isEmpty
              ? _buildEmptyState('You have no completed listings.')
              : ListView.builder(
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
