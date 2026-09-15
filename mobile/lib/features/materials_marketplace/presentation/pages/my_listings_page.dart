import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../providers/material_listings_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/my_listing_card.dart';

class MyListingsPage extends ConsumerStatefulWidget {
  const MyListingsPage({super.key});

  @override
  ConsumerState<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends ConsumerState<MyListingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Local state for completed listings until backend supports fetching them
  final List<MaterialListing> _completedListings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                // Status 2 = Deleted
                await ref.read(activeListingsNotifierProvider.notifier).changeStatus(listing.id, 2);
                if (!isActive) {
                  setState(() {
                    _completedListings.removeWhere((l) => l.id == listing.id);
                  });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAsSold(MaterialListing listing) async {
    try {
      // Status 1 = Completed
      await ref.read(activeListingsNotifierProvider.notifier).changeStatus(listing.id, 1);
      setState(() {
        _completedListings.insert(0, listing);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as sold: $e')),
        );
      }
    }
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
          ref.watch(activeListingsNotifierProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (listings) {
                  // Get the current user's profile
                  final profile = ref.watch(profileNotifierProvider).value;
                  
                  // Filter listings to only show ones owned by the current user
                  final myActive = profile != null 
                    ? listings.where((l) => l.businessId == profile.id).toList() 
                    : <MaterialListing>[];
                  
                  if (myActive.isEmpty) {
                    return _buildEmptyState('You have no active listings.');
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: myActive.length,
                    itemBuilder: (context, index) {
                      return MyListingCard(
                        listing: myActive[index],
                        isActive: true,
                        onEdit: () {
                          // TODO: Navigate to Edit screen
                        },
                        onDelete: () => _deleteListing(myActive[index], true),
                        onMarkSold: () => _markAsSold(myActive[index]),
                      );
                    },
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
