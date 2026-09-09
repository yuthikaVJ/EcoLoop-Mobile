import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/material_listing.dart';
import '../widgets/material_listing_card.dart';

class MaterialsMarketplacePage extends StatefulWidget {
  const MaterialsMarketplacePage({super.key});

  @override
  State<MaterialsMarketplacePage> createState() => _MaterialsMarketplacePageState();
}

class _MaterialsMarketplacePageState extends State<MaterialsMarketplacePage> {
  // Filter listings based on the tab
  List<MaterialListing> get iHaveListings => 
      dummyListings.where((listing) => listing.isIHave).toList();
      
  List<MaterialListing> get iNeedListings => 
      dummyListings.where((listing) => !listing.isIHave).toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Materials Marketplace'),
          bottom: const TabBar(
            indicatorColor: AppColors.forestGreen,
            labelColor: AppColors.forestGreen,
            unselectedLabelColor: AppColors.slateGray,
            tabs: [
              Tab(text: 'I Have'),
              Tab(text: 'I Need'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search and Filters Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.mintGreen),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text('Category'),
                        Icon(Icons.arrow_drop_down, color: AppColors.slateGray),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.mintGreen),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text('Location'),
                        Icon(Icons.arrow_drop_down, color: AppColors.slateGray),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.sort, color: AppColors.darkCharcoal),
                    onPressed: () {},
                  )
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  // I Have Tab
                  ListView.builder(
                    itemCount: iHaveListings.length,
                    itemBuilder: (context, index) {
                      return MaterialListingCard(listing: iHaveListings[index]);
                    },
                  ),
                  // I Need Tab
                  ListView.builder(
                    itemCount: iNeedListings.length,
                    itemBuilder: (context, index) {
                      return MaterialListingCard(listing: iNeedListings[index]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.forestGreen,
          child: const Icon(Icons.add, color: AppColors.white),
          onPressed: () {
            // TODO: Navigate to Add Material Form Screen
          },
        ),
      ),
    );
  }
}
