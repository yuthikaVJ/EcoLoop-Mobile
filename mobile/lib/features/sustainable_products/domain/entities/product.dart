class Product {
  final String id, businessId, name, description, seller;
  final double price;
  final int availableQuantity;
  final bool sellerDeliveryAvailable;

  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.description,
    required this.seller,
    required this.price,
    required this.availableQuantity,
    required this.sellerDeliveryAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    businessId: json['businessId'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    seller: json['seller'] as String? ?? 'Seller',
    price: (json['price'] as num).toDouble(),
    availableQuantity: json['availableQuantity'] as int,
    sellerDeliveryAvailable: json['sellerDeliveryAvailable'] == true,
  );
}
