class Product {
  final String id;
  final String? businessId; // seller business
  final String name;
  final String description;
  final String materialType;
  final double price;
  final String? category;
  final String? seller;
  final bool sellerIsVerified;
  final int availableQuantity;
  final bool sellerDeliveryAvailable; // buyer may choose Seller Delivery
  final String? primaryImageUrl;
  final List<String> images;

  const Product({
    required this.id,
    this.businessId,
    required this.name,
    required this.description,
    required this.materialType,
    required this.price,
    required this.category,
    required this.seller,
    required this.sellerIsVerified,
    required this.availableQuantity,
    this.sellerDeliveryAvailable = false,
    required this.primaryImageUrl,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imageList = (json['images'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Product(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      materialType: json['materialType'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String?,
      seller: json['seller'] as String?,
      sellerIsVerified: json['sellerIsVerified'] as bool? ?? false,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      sellerDeliveryAvailable: json['sellerDeliveryAvailable'] as bool? ?? false,
      primaryImageUrl: json['primaryImageUrl'] as String? ??
          (imageList.isEmpty ? null : imageList.first),
      images: imageList,
    );
  }

  Product copyWith({
    String? id,
    String? businessId,
    String? name,
    String? description,
    String? materialType,
    double? price,
    String? category,
    String? seller,
    bool? sellerIsVerified,
    int? availableQuantity,
    bool? sellerDeliveryAvailable,
    String? primaryImageUrl,
    List<String>? images,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      materialType: materialType ?? this.materialType,
      price: price ?? this.price,
      category: category ?? this.category,
      seller: seller ?? this.seller,
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      sellerDeliveryAvailable:
          sellerDeliveryAvailable ?? this.sellerDeliveryAvailable,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      images: images ?? this.images,
    );
  }
}
