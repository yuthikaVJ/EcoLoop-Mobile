class MaterialListing {
  final String description;
  final String quantityValue;
  final String id;
  final String title;
  final String category;
  final String quantity;
  final String location;
  final String companyName;
  final double price;
  final String priceUnit;
  final bool isVerifiedSeller;
  final String imageUrl;
  final bool isIHave; // true for 'I HAVE', false for 'I NEED'
  final DateTime datePosted;
  final String businessId;
  final String unit;
  final bool sellerDeliveryAvailable;
  final int status; // 0 = Active, 1 = Completed, 2 = Deleted

  MaterialListing({
    this.description = '',
    this.quantityValue = '',
    required this.id,
    required this.title,
    required this.category,
    required this.quantity,
    required this.location,
    required this.companyName,
    required this.price,
    required this.priceUnit,
    required this.isVerifiedSeller,
    required this.imageUrl,
    required this.isIHave,
    required this.datePosted,
    this.businessId = '11111111-1111-1111-1111-111111111111',
    this.unit = 'Tons',
    this.sellerDeliveryAvailable = false,
    this.status = 0,
  });

  // Maps MaterialListingListDto / MaterialListingDetailsDto from the backend.
  // Null-safe so one incomplete record can't crash a whole list.
  factory MaterialListing.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity']?.toString() ?? '';
    final unit = json['unit']?.toString() ?? '';
    final seller = json['seller']?.toString() ?? '';
    return MaterialListing(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OTHER',
      quantity: unit.isEmpty ? quantity : '$quantity $unit',
      quantityValue: quantity,
      location: json['location']?.toString() ?? '',
      companyName: seller.isEmpty ? 'Unknown Seller' : seller,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      priceUnit: json['priceUnit']?.toString() ?? '',
      isVerifiedSeller: json['sellerIsVerified'] == true,
      imageUrl: json['imageUrl']?.toString() ?? '',
      isIHave: (json['type'] as num?)?.toInt() != 1,
      datePosted:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      businessId: json['businessId']?.toString() ?? '',
      unit: unit,
      sellerDeliveryAvailable: json['sellerDeliveryAvailable'] == true,
      description: json['description']?.toString() ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }
}

// Dummy data for development
List<MaterialListing> get dummyListings => [
  MaterialListing(
    id: '1',
    title: 'Clean LDPE Pellets',
    category: 'PLASTICS',
    quantity: '10 Tons',
    location: 'Sector 4, Industrial Area',
    companyName: 'NovaFlow Recycling',
    price: 450.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: true,
    datePosted: DateTime.now().subtract(const Duration(days: 2)),
  ),
  MaterialListing(
    id: '2',
    title: 'Corrugated Cardboard Bales',
    category: 'PAPER',
    quantity: '150 Bales',
    location: 'East Port Terminal',
    companyName: 'Global Fiber Co.',
    price: 120.0,
    priceUnit: 'Ton',
    isVerifiedSeller: false,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: true,
    datePosted: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  MaterialListing(
    id: '3',
    title: 'Scrap Brass Turnings',
    category: 'METALS',
    quantity: '2.5 Tons',
    location: 'North Rail Yard',
    companyName: 'EcoMetals Inc',
    price: 1800.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: true,
    datePosted: DateTime.now().subtract(const Duration(days: 1)),
  ),
  MaterialListing(
    id: '4',
    title: 'Used Glass Bottles (Mixed Colors)',
    category: 'GLASS',
    quantity: '5 Tons',
    location: 'Downtown sorting facility',
    companyName: 'GreenGlass Operations',
    price: 90.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: false,
    datePosted: DateTime.now().subtract(const Duration(minutes: 45)),
  ),
  MaterialListing(
    id: '5',
    title: 'Industrial Wood Pallets',
    category: 'WOOD',
    quantity: '200 Units',
    location: 'Westside Logistics Park',
    companyName: 'TimberRecycle',
    price: 5.0,
    priceUnit: 'Unit',
    isVerifiedSeller: false,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: true,
    datePosted: DateTime.now().subtract(const Duration(days: 4)),
  ),
  MaterialListing(
    id: '6',
    title: 'Recycled Aluminum Cans',
    category: 'METALS',
    quantity: '1.5 Tons',
    location: 'City Center Hub',
    companyName: 'AlumCo',
    price: 1200.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: true,
    datePosted: DateTime.now().subtract(const Duration(days: 7)),
  ),
  MaterialListing(
    id: '7',
    title: 'Scrap Copper Wire',
    category: 'METALS',
    quantity: '500 Kgs',
    location: 'East Industrial Estate',
    companyName: 'EcoWiring',
    price: 3500.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: true,
    datePosted: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  MaterialListing(
    id: '8',
    title: 'Mixed Paper Waste',
    category: 'PAPER',
    quantity: '20 Tons',
    location: 'Southside Facility',
    companyName: 'PaperCycle',
    price: 80.0,
    priceUnit: 'Ton',
    isVerifiedSeller: false,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: false,
    datePosted: DateTime.now().subtract(const Duration(days: 3)),
  ),
  MaterialListing(
    id: '9',
    title: 'PET Plastic Bottles Needed',
    category: 'PLASTICS',
    quantity: '50 Tons',
    location: 'Northside Processing Plant',
    companyName: 'EcoPlast',
    price: 300.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: false,
    datePosted: DateTime.now().subtract(const Duration(days: 1)),
  ),
  MaterialListing(
    id: '10',
    title: 'Old Electronic Circuit Boards',
    category: 'E-WASTE',
    quantity: '500 Kgs',
    location: 'Tech Hub Center',
    companyName: 'CircuitRecycle',
    price: 5000.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: false,
    datePosted: DateTime.now().subtract(const Duration(days: 5)),
  ),
  MaterialListing(
    id: '11',
    title: 'Clean Cardboard Boxes',
    category: 'PAPER',
    quantity: '1000 Units',
    location: 'City Market Area',
    companyName: 'PackAndShip',
    price: 0.5,
    priceUnit: 'Unit',
    isVerifiedSeller: false,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: false,
    datePosted: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  MaterialListing(
    id: '12',
    title: 'Scrap Steel Pipes',
    category: 'METALS',
    quantity: '10 Tons',
    location: 'Heavy Industry Zone',
    companyName: 'SteelWorks Ltd',
    price: 250.0,
    priceUnit: 'Ton',
    isVerifiedSeller: true,
    imageUrl: 'https://via.placeholder.com/150',
    isIHave: false,
    datePosted: DateTime.now().subtract(const Duration(days: 10)),
  ),
];
