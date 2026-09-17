class Product {
  final String id;
  final String name;
  final String description;
  final String materialType;
  final double price;
  final String? category;
  final String? seller;
  final bool sellerIsVerified;
  final int availableQuantity;
  final String? primaryImageUrl;
  final List<String> images;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.materialType,
    required this.price,
    required this.category,
    required this.seller,
    required this.sellerIsVerified,
    required this.availableQuantity,
    required this.primaryImageUrl,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imageList = (json['images'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      materialType: json['materialType'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      seller: json['seller'] as String?,
      sellerIsVerified: json['sellerIsVerified'] as bool? ?? false,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      primaryImageUrl: json['primaryImageUrl'] as String? ??
          (imageList.isEmpty ? null : imageList.first),
      images: imageList,
    );
  }
}