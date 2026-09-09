class MaterialListing {
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

  MaterialListing({
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
  });
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
    imageUrl: 'https://via.placeholder.com/150', // Replace with real asset later
    isIHave: true,
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
  )
];
