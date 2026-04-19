class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String source;
  final String brand;
  final double rating;
  final String description;
  final String category;
  final int reviewCount;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.source,
    required this.brand,
    required this.rating,
    required this.description,
    this.category = 'Electronics',
    this.reviewCount = 0,
    this.inStock = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? json['title'] ?? 'Unknown Product',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? json['thumbnail'] ?? '',
      source: json['source'] ?? json['website'] ?? 'Store',
      brand: json['brand'] ?? 'Generic',
      rating: (json['rating'] ?? 4.0).toDouble(),
      description: json['description'] ?? 'No description available',
      category: json['category'] ?? 'Electronics',
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
      inStock: json['in_stock'] ?? json['inStock'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'source': source,
      'brand': brand,
      'rating': rating,
      'description': description,
      'category': category,
      'review_count': reviewCount,
      'in_stock': inStock,
    };
  }
}
