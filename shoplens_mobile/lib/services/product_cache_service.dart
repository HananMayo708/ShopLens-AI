import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';

class ProductCacheService {
  static const String _productBox = 'products_cache';
  static const int _maxProducts = 1000;

  // FIX: Make box nullable instead of late
  Box? _box;
  bool _isInitialized = false;

  // Singleton pattern to ensure single instance
  static final ProductCacheService _instance = ProductCacheService._internal();
  factory ProductCacheService() => _instance;
  ProductCacheService._internal();

  // Initialize Hive
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_productBox);
      _isInitialized = true;
      print('📦 Product cache initialized with ${_box?.length ?? 0} products');
    } catch (e) {
      print('❌ Failed to initialize product cache: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // Ensure box is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized || _box == null) {
      await init();
    }
  }

  // Save products to local cache (max 1000)
  Future<void> saveProducts(List<Product> products) async {
    await _ensureInitialized();

    if (_box == null) {
      print('❌ Cache box not initialized');
      return;
    }

    try {
      // Limit to 1000 products
      final limitedProducts = products.take(_maxProducts).toList();

      // Clear old cache
      await _box!.clear();

      // Save each product with complete data including productUrl
      for (int i = 0; i < limitedProducts.length; i++) {
        final product = limitedProducts[i];
        final jsonData = {
          'id': product.id,
          'name': product.name,
          'price': product.price,
          'image_url': product.imageUrl,
          'source': product.source,
          'brand': product.brand,
          'rating': product.rating,
          'description': product.description,
          'category': product.category,
          'review_count': product.reviewCount,
          'in_stock': product.inStock,
          'product_url': product.productUrl,
        };
        await _box!.put(product.id, jsonEncode(jsonData));
      }

      print(
          '💾 Cached ${limitedProducts.length} products (max: $_maxProducts)');
    } catch (e) {
      print('❌ Failed to cache products: $e');
    }
  }

  // Get cached products
  Future<List<Product>> getCachedProducts() async {
    await _ensureInitialized();

    if (_box == null) {
      print('❌ Cache box not initialized');
      return [];
    }

    try {
      if (_box!.isEmpty) {
        print('📭 No cached products found');
        return [];
      }

      final List<Product> products = [];
      for (var key in _box!.keys) {
        final jsonString = _box!.get(key) as String;
        final Map<String, dynamic> json = jsonDecode(jsonString);
        products.add(Product.fromJson(json));
      }

      print('📦 Loaded ${products.length} products from cache');
      return products;
    } catch (e) {
      print('❌ Failed to load cached products: $e');
      return [];
    }
  }

  // Check if cache has products
  Future<bool> hasCachedProducts() async {
    await _ensureInitialized();
    return _box != null && _box!.isNotEmpty;
  }

  // Get cache size
  Future<int> getCacheSize() async {
    await _ensureInitialized();
    return _box?.length ?? 0;
  }

  // Clear cache
  Future<void> clearCache() async {
    await _ensureInitialized();

    if (_box == null) return;

    try {
      await _box!.clear();
      print('🗑️ Product cache cleared');
    } catch (e) {
      print('❌ Failed to clear cache: $e');
    }
  }
}
