import '../../../../core/config/app_config.dart';

class MaterialListing {
  final String id;
  final String? businessId;
  final String title;
  final String category;
  final String description;
  final String quantity; // raw amount, e.g. "20" (see [unit])
  final String unit;
  final String location;
  final double price;
  final String priceUnit;
  final String deliveryMethod;
  final bool sellerDeliveryAvailable; // buyer may choose Seller Delivery
  final String? companyName; // maps to 'seller'
  final bool isVerifiedSeller; // maps to 'sellerIsVerified'
  final String? sellerLogoUrl; // maps to 'sellerLogoUrl'
  final String? availability; // e.g. 'Immediately', 'Within a week', 'Flexible'
  final String? condition;
  final bool isIHave; // maps to 'type' == 0
  final int status; // 0 = active, 1 = completed, 2 = deleted
  final DateTime datePosted; // maps to 'createdAt'
  final String imageUrl; // first photo (or a placeholder)
  final List<String> imageUrls; // every photo, in order

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
    this.sellerDeliveryAvailable = false,
    this.companyName,
    required this.isVerifiedSeller,
    this.sellerLogoUrl,
    this.availability,
    this.condition,
    required this.isIHave,
    required this.status,
    required this.datePosted,
    this.imageUrl = 'https://via.placeholder.com/150',
    this.imageUrls = const [],
  });

  /// Photos for the slider: every uploaded photo, or just [imageUrl] for
  /// listings created before multiple photos were supported.
  List<String> get photos => imageUrls.isNotEmpty ? imageUrls : [imageUrl];

  /// Photos actually uploaded (no placeholder), for editing.
  List<String> get uploadedPhotos => imageUrls.isNotEmpty
      ? imageUrls
      : imageUrl.contains('via.placeholder.com')
          ? const []
          : [imageUrl];

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
      sellerDeliveryAvailable: json['sellerDeliveryAvailable'] as bool? ?? false,
      companyName: json['seller'] as String?,
      isVerifiedSeller: json['sellerIsVerified'] as bool? ?? false,
      sellerLogoUrl: json['sellerLogoUrl'] as String?,
      availability: json['availability'] as String?,
      condition: json['condition'] as String?,
      isIHave: (json['type'] as int?) == 0,
      status: json['status'] as int? ?? 0,
      datePosted: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      // The server stores photos as "/uploads/..." paths (older rows: emulator
      // links); mediaUrl turns both into a full URL for this app's server.
      imageUrl: AppConfig.mediaUrl(json['imageUrl'] as String?) ?? 'https://via.placeholder.com/150',
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .map(AppConfig.mediaUrl)
          .whereType<String>()
          .toList(),
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
      'sellerDeliveryAvailable': sellerDeliveryAvailable,
      'type': isIHave ? 0 : 1,
      'status': status,
    };
  }
}
