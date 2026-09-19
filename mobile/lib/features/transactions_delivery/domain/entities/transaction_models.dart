enum DeliveryMethod { selfPickup, sellerDelivery }

class DeliveryInfo {
  final String id;
  final DeliveryMethod method;
  final String? location;

  const DeliveryInfo({required this.id, required this.method, this.location});

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) => DeliveryInfo(
        id: json['id']?.toString() ?? '',
        method: (json['method'] as num? ?? 0).toInt() == 1
            ? DeliveryMethod.sellerDelivery
            : DeliveryMethod.selfPickup,
        location: json['location'] as String?,
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

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) => StatusHistoryEntry(
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

  factory MaterialTransactionSummary.fromJson(Map<String, dynamic> json) => MaterialTransactionSummary(
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
      buyerBusinessId: json['buyerBusinessId'].toString(),
      sellerBusinessId: json['sellerBusinessId'].toString(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      delivery: json['delivery'] == null ? null : DeliveryInfo.fromJson(json['delivery']),
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

  factory ProductOrderSummary.fromJson(Map<String, dynamic> json) => ProductOrderSummary(
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

  const ProductOrderItem({required this.productId, required this.productName, required this.quantity, required this.unitPrice, required this.lineTotal});

  factory ProductOrderItem.fromJson(Map<String, dynamic> json) => ProductOrderItem(
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
      buyerBusinessId: json['buyerBusinessId'].toString(),
      sellerBusinessId: json['sellerBusinessId'].toString(),
      items: (json['items'] as List? ?? []).map((x) => ProductOrderItem.fromJson(x)).toList(),
      delivery: json['delivery'] == null ? null : DeliveryInfo.fromJson(json['delivery']),
      statusHistory: (json['statusHistory'] as List? ?? []).map((x) => StatusHistoryEntry.fromJson(x)).toList(),
    );
  }
}
