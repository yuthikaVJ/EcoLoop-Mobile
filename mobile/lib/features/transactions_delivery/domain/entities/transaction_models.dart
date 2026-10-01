enum DeliveryMethod { selfPickup, sellerDelivery }

/// Progress of a Seller Delivery (the seller is the driver).
enum DeliveryProgress { notStarted, onTheWay, delivered }

class DeliveryInfo {
  final String id;
  final DeliveryMethod method;
  final String? location;
  final DeliveryProgress progress;
  final double? sellerLatitude;
  final double? sellerLongitude;
  final DateTime? sellerLocationAt;

  const DeliveryInfo({
    required this.id,
    required this.method,
    this.location,
    this.progress = DeliveryProgress.notStarted,
    this.sellerLatitude,
    this.sellerLongitude,
    this.sellerLocationAt,
  });

  bool get hasSellerPosition => sellerLatitude != null && sellerLongitude != null;

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) => DeliveryInfo(
    id: json['id']?.toString() ?? '',
    method: (json['method'] as num? ?? 0).toInt() == 1
        ? DeliveryMethod.sellerDelivery
        : DeliveryMethod.selfPickup,
    location: json['location'] as String?,
    progress: deliveryProgressFrom((json['status'] as num?)?.toInt()),
    sellerLatitude: (json['currentLatitude'] as num?)?.toDouble(),
    sellerLongitude: (json['currentLongitude'] as num?)?.toDouble(),
    sellerLocationAt: DateTime.tryParse(
      json['locationUpdatedAt']?.toString() ?? '',
    )?.toLocal(),
  );
}

DeliveryProgress deliveryProgressFrom(int? value) => switch (value) {
  1 => DeliveryProgress.onTheWay,
  2 => DeliveryProgress.delivered,
  _ => DeliveryProgress.notStarted,
};

/// A Seller Delivery job as the seller sees it on "My Deliveries".
class SellerDeliveryJob {
  final String id;
  final bool isProductOrder;
  final String parentId;
  final String title;
  final String buyer;
  final String? destination;
  final double totalAmount;
  final String parentStatus;
  final DeliveryProgress progress;
  final double? latitude;
  final double? longitude;
  final DateTime? locationAt;

  const SellerDeliveryJob({
    required this.id,
    required this.isProductOrder,
    required this.parentId,
    required this.title,
    required this.buyer,
    required this.destination,
    required this.totalAmount,
    required this.parentStatus,
    required this.progress,
    this.latitude,
    this.longitude,
    this.locationAt,
  });

  /// The seller can only set off once the order/transaction is Ready.
  bool get canStart =>
      progress == DeliveryProgress.notStarted && parentStatus == 'Ready';

  factory SellerDeliveryJob.fromJson(Map<String, dynamic> json) =>
      SellerDeliveryJob(
        id: json['id'].toString(),
        isProductOrder: json['kind'] == 'product',
        parentId: json['parentId'].toString(),
        title: json['title']?.toString() ?? '',
        buyer: json['buyer']?.toString() ?? '',
        destination: json['destination'] as String?,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        parentStatus: json['parentStatusName']?.toString() ?? '',
        progress: deliveryProgressFrom((json['status'] as num?)?.toInt()),
        latitude: (json['currentLatitude'] as num?)?.toDouble(),
        longitude: (json['currentLongitude'] as num?)?.toDouble(),
        locationAt: DateTime.tryParse(
          json['locationUpdatedAt']?.toString() ?? '',
        )?.toLocal(),
      );
}

class StatusHistoryEntry {
  final String statusName;
  final String? changedByBusinessName;
  final String? note;
  final DateTime createdAt;

  const StatusHistoryEntry({
    required this.statusName,
    this.changedByBusinessName,
    this.note,
    required this.createdAt,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      StatusHistoryEntry(
        statusName: json['statusName']?.toString() ?? '',
        changedByBusinessName: json['changedByBusinessName'] as String?,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}

class MaterialTransactionSummary {
  final String id;
  final String listingTitle;
  final String buyer;
  final String seller;
  final double quantity;
  final String unit;
  final double totalAmount;
  final String statusName;
  final DeliveryMethod deliveryMethod;
  final DateTime createdAt;

  const MaterialTransactionSummary({
    required this.id,
    required this.listingTitle,
    required this.buyer,
    required this.seller,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.statusName,
    required this.deliveryMethod,
    required this.createdAt,
  });

  factory MaterialTransactionSummary.fromJson(Map<String, dynamic> json) =>
      MaterialTransactionSummary(
        id: json['id'].toString(),
        listingTitle: json['listingTitle']?.toString() ?? '',
        buyer: json['buyer']?.toString() ?? '',
        seller: json['seller']?.toString() ?? '',
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num).toDouble(),
        statusName: json['statusName']?.toString() ?? '',
        deliveryMethod: (json['deliveryMethod'] as num? ?? 0).toInt() == 1
            ? DeliveryMethod.sellerDelivery
            : DeliveryMethod.selfPickup,
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}

class MaterialTransactionDetails extends MaterialTransactionSummary {
  final String buyerBusinessId;
  final String sellerBusinessId;
  final double unitPrice;
  final DeliveryInfo? delivery;
  final List<StatusHistoryEntry> statusHistory;
  final String? updatedAt;

  const MaterialTransactionDetails({
    required super.id,
    required super.listingTitle,
    required super.buyer,
    required super.seller,
    required super.quantity,
    required super.unit,
    required super.totalAmount,
    required super.statusName,
    required super.deliveryMethod,
    required super.createdAt,
    required this.buyerBusinessId,
    required this.sellerBusinessId,
    required this.unitPrice,
    this.delivery,
    required this.statusHistory,
    this.updatedAt,
  });

  factory MaterialTransactionDetails.fromJson(Map<String, dynamic> json) {
    final summary = MaterialTransactionSummary.fromJson(json);
    return MaterialTransactionDetails(
      id: summary.id,
      listingTitle: summary.listingTitle,
      buyer: summary.buyer,
      seller: summary.seller,
      quantity: summary.quantity,
      unit: summary.unit,
      totalAmount: summary.totalAmount,
      statusName: summary.statusName,
      deliveryMethod: summary.deliveryMethod,
      createdAt: summary.createdAt,
      updatedAt: json['updatedAt'] as String?,
      buyerBusinessId: json['buyerBusinessId'].toString(),
      sellerBusinessId: json['sellerBusinessId'].toString(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      delivery: json['delivery'] == null
          ? null
          : DeliveryInfo.fromJson(json['delivery']),
      statusHistory: (json['statusHistory'] as List? ?? [])
          .map((x) => StatusHistoryEntry.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductOrderSummary {
  final String id;
  final String buyer;
  final String seller;
  final int itemCount;
  final double totalAmount;
  final String statusName;
  final DeliveryMethod deliveryMethod;
  final DateTime createdAt;

  const ProductOrderSummary({
    required this.id,
    required this.buyer,
    required this.seller,
    required this.itemCount,
    required this.totalAmount,
    required this.statusName,
    required this.deliveryMethod,
    required this.createdAt,
  });

  factory ProductOrderSummary.fromJson(Map<String, dynamic> json) =>
      ProductOrderSummary(
        id: json['id'].toString(),
        buyer: json['buyer']?.toString() ?? '',
        seller: json['seller']?.toString() ?? '',
        itemCount: (json['itemCount'] as num).toInt(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        statusName: json['statusName']?.toString() ?? '',
        deliveryMethod: (json['deliveryMethod'] as num? ?? 0).toInt() == 1
            ? DeliveryMethod.sellerDelivery
            : DeliveryMethod.selfPickup,
        createdAt: DateTime.parse(json['createdAt'].toString()),
      );
}

class ProductOrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const ProductOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory ProductOrderItem.fromJson(Map<String, dynamic> json) =>
      ProductOrderItem(
        productId: json['productId'].toString(),
        productName: json['productName'].toString(),
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        lineTotal: (json['lineTotal'] as num).toDouble(),
      );
}

class ProductOrderDetails extends ProductOrderSummary {
  final String buyerBusinessId;
  final String sellerBusinessId;
  final List<ProductOrderItem> items;
  final DeliveryInfo? delivery;
  final List<StatusHistoryEntry> statusHistory;
  final String? updatedAt;

  const ProductOrderDetails({
    required super.id,
    required super.buyer,
    required super.seller,
    required super.itemCount,
    required super.totalAmount,
    required super.statusName,
    required super.deliveryMethod,
    required super.createdAt,
    required this.buyerBusinessId,
    required this.sellerBusinessId,
    required this.items,
    this.delivery,
    required this.statusHistory,
    this.updatedAt,
  });

  factory ProductOrderDetails.fromJson(Map<String, dynamic> json) {
    final summary = ProductOrderSummary.fromJson(json);
    return ProductOrderDetails(
      id: summary.id,
      buyer: summary.buyer,
      seller: summary.seller,
      itemCount: summary.itemCount,
      totalAmount: summary.totalAmount,
      statusName: summary.statusName,
      deliveryMethod: summary.deliveryMethod,
      createdAt: summary.createdAt,
      updatedAt: json['updatedAt'] as String?,
      buyerBusinessId: json['buyerBusinessId'].toString(),
      sellerBusinessId: json['sellerBusinessId'].toString(),
      items: (json['items'] as List? ?? [])
          .map((x) => ProductOrderItem.fromJson(x))
          .toList(),
      delivery: json['delivery'] == null
          ? null
          : DeliveryInfo.fromJson(json['delivery']),
      statusHistory: (json['statusHistory'] as List? ?? [])
          .map((x) => StatusHistoryEntry.fromJson(x))
          .toList(),
    );
  }
}
