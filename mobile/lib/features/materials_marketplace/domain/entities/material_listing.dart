class MaterialListing {
  final String id;
  final String? businessId;
  final String title;
  final String category;
  final String description;
  final String quantity;
  final String unit;
  final String location;
  final double price;
  final String priceUnit;
  final String deliveryMethod;
  final String? companyName; // maps to 'seller'
  final bool isVerifiedSeller; // maps to 'sellerIsVerified'
  final bool isIHave; // maps to 'type' == 0
  final int status; // 0 = active, 1 = completed, 2 = deleted
  final DateTime datePosted; // maps to 'createdAt'
  final String imageUrl; // We'll keep this hardcoded or handle it later since image upload isn't fully integrated on backend

  MaterialListing({
    required this.id,
    this.businessId,
    required this.title,
    required this.category,
    this.description = '',
    required this.quantity,
    this.unit = '',
    required this.location,
    required this.price,
    required this.priceUnit,
    this.deliveryMethod = '',
    this.companyName,
    required this.isVerifiedSeller,
    required this.isIHave,
    required this.status,
    required this.datePosted,
    this.imageUrl = 'https://via.placeholder.com/150',
  });

  factory MaterialListing.fromJson(Map<String, dynamic> json) {
    return MaterialListing(
      id: json['id'] as String,
      businessId: json['businessId'] as String?,
      title: json['title'] as String? ?? 'Unknown Title',
      category: json['category'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '0',
      unit: json['unit'] as String? ?? '',
      location: json['location'] as String? ?? 'Unknown Location',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceUnit: json['priceUnit'] as String? ?? '',
      deliveryMethod: json['deliveryMethod'] as String? ?? '',
      companyName: json['seller'] as String?,
      isVerifiedSeller: json['sellerIsVerified'] as bool? ?? false,
      isIHave: (json['type'] as int?) == 0,
      status: json['status'] as int? ?? 0,
      datePosted: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      imageUrl: json['imageUrl'] as String? ?? 'https://via.placeholder.com/150', 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'category': category,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'price': price,
      'priceUnit': priceUnit,
      'deliveryMethod': deliveryMethod,
      'type': isIHave ? 0 : 1,
      'status': status,
    };
  }
}
