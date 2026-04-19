class PriceAlert {
  final String id;
  final String productId;
  final String productName;
  final double targetPrice;
  final double currentPrice;
  final String imageUrl;
  final DateTime createdAt;
  bool isNotified;

  PriceAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.targetPrice,
    required this.currentPrice,
    required this.imageUrl,
    required this.createdAt,
    this.isNotified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'targetPrice': targetPrice,
      'currentPrice': currentPrice,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isNotified': isNotified,
    };
  }

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      targetPrice: json['targetPrice'].toDouble(),
      currentPrice: json['currentPrice'].toDouble(),
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isNotified: json['isNotified'] ?? false,
    );
  }
}
