import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';

class ProductCacheService {
  static const String _productBox = 'products_cache';
  static const int _maxProducts = 1000;
  
  late Box _box;
  
  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_productBox);
    print('📦 Product cache initialized with ${_box.length} products');
  }
  
  // Save products to local cache (max 1000)
  Future<void> saveProducts(List<Product> products) async {
    try {
      // Limit to 1000 products
      final limitedProducts = products.take(_maxProducts).toList();
      
      // Clear old cache
      await _box.clear();
      
      // Save each product
      for (int i = 0; i < limitedProducts.length; i++) {
        final product = limitedProducts[i];
        await _box.put(product.id, jsonEncode(product.toJson()));
      }
      
      print('💾 Cached ${limitedProducts.length} products (max: $_maxProducts)');
    } catch (e) {
      print('❌ Failed to cache products: $e');
    }
  }
  
  // Get cached products
  Future<List<Product>> getCachedProducts() async {
    try {
      if (_box.isEmpty) {
        print('📭 No cached products found');
        return [];
      }
      
      final List<Product> products = [];
      for (var key in _box.keys) {
        final jsonString = _box.get(key) as String;
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
    return _box.isNotEmpty;
  }
  
  // Get cache size
  Future<int> getCacheSize() async {
    return _box.length;
  }
  
  // Clear cache
  Future<void> clearCache() async {
    await _box.clear();
    print('🗑️ Product cache cleared');
  }
}
