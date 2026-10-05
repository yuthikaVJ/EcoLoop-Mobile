# Add Edit Functionality for User Listings

The user wants the ability to edit the materials and products they have posted. Currently, the "Edit" button in "My Listings" (Materials) does nothing, and there is no edit button in the newly created "My Products" screen.

## Proposed Changes

### 1. Materials Marketplace
- Create `lib/features/materials_marketplace/presentation/pages/edit_material_page.dart`.
  - It will be similar to `add_material_page.dart`, but initialized with an existing `MaterialListing`.
  - It will call a new `editListing` method in `MaterialListingsNotifier`.
- Update `material_listings_provider.dart` and `material_listing_repository.dart` to support PUT updates for a material.
- Update `my_listings_page.dart` to navigate to `EditMaterialPage` when the "Edit" button is tapped.

### 2. Sustainable Products Marketplace
- Update `my_products_page.dart` to display Edit and Delete buttons (or use a Swipe-to-Action / bottom sheet) for each product.
- Create `lib/features/sustainable_products/presentation/pages/edit_product_page.dart`.
  - It will be similar to `add_product_page.dart`, initialized with an existing `Product`.
- Update `product_repository.dart` to support PUT updates and DELETE (disable) for products.

## User Review Required
Does this plan sound good? I can build out the Edit screens so you can finally update your posted items!
