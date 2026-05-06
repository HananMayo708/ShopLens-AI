class PriceAlert {
  final int id;
  final String productId;
  final String productName;
  final String productUrl;
  final String productImage;
  final double targetPrice;
  final double currentPrice;
  final bool isNotified;
  final String sourceStore;
  final DateTime createdAt;

  PriceAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productUrl,
    required this.productImage,
    required this.targetPrice,
    required this.currentPrice,
    required this.isNotified,
    required this.sourceStore,
    required this.createdAt,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productUrl: json['product_url'] ?? '',
      productImage: json['product_image'] ?? '',
      targetPrice: (json['target_price'] ?? 0).toDouble(),
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      isNotified: json['is_notified'] ?? false,
      sourceStore: json['source_store'] ?? 'Amazon',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_url': productUrl,
      'product_image': productImage,
      'target_price': targetPrice,
      'current_price': currentPrice,
      'is_notified': isNotified,
      'source_store': sourceStore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PriceAlert copyWith({
    int? id,
    String? productId,
    String? productName,
    String? productUrl,
    String? productImage,
    double? targetPrice,
    double? currentPrice,
    bool? isNotified,
    String? sourceStore,
    DateTime? createdAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productUrl: productUrl ?? this.productUrl,
      productImage: productImage ?? this.productImage,
      targetPrice: targetPrice ?? this.targetPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      isNotified: isNotified ?? this.isNotified,
      sourceStore: sourceStore ?? this.sourceStore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
