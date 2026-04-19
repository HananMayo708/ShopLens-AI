import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/product_cache_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductCacheService _cacheService = ProductCacheService();

  List<Product> _featuredProducts = [];
  List<Product> _popularProducts = [];
  List<Product> _electronicsProducts = [];
  List<Product> _gamingProducts = [];
  List<Product> _homeProducts = [];
  List<Product> _fashionProducts = [];
  List<Product> _recentlyViewed = [];

  bool _isLoading = true;
  bool _isOnline = true;
  String? _error;

  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get popularProducts => _popularProducts;
  List<Product> get electronicsProducts => _electronicsProducts;
  List<Product> get gamingProducts => _gamingProducts;
  List<Product> get homeProducts => _homeProducts;
  List<Product> get fashionProducts => _fashionProducts;
  List<Product> get recentlyViewed => _recentlyViewed;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;

  ProductProvider() {
    _initCache();
  }

  Future<void> _initCache() async {
    await _cacheService.init();
  }

  // Add to recently viewed
  void addToRecentlyViewed(Product product) {
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    _recentlyViewed.insert(0, product);
    if (_recentlyViewed.length > 20) {
      _recentlyViewed = _recentlyViewed.take(20).toList();
    }
    notifyListeners();
  }

  // WEB-COMPATIBLE internet connection check
  Future<bool> _hasInternet() async {
    try {
      // This works on both Web and Mobile
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('🌐 Internet check failed: $e');
      return false;
    }
  }

  // MAIN METHOD: Load products with offline-first strategy
  Future<void> loadHomeProducts({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Check internet status
    _isOnline = await _hasInternet();
    print('🌐 Internet status: ${_isOnline ? "ONLINE" : "OFFLINE"}');

    if (_isOnline && !forceRefresh) {
      await _fetchOnlineProducts();
    } else if (_isOnline && forceRefresh) {
      await _fetchOnlineProducts();
    } else {
      await _loadFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch products from API and cache them
  Future<void> _fetchOnlineProducts() async {
    print('🌐 Fetching products from API...');

    try {
      final categories = [
        'laptop',
        'smartphone',
        'headphones',
        'gaming',
        'home',
        'fashion'
      ];
      List<Product> allProducts = [];

      for (String category in categories) {
        final products = await ApiService.searchProducts(category, limit: 50);
        for (var product in products) {
          // Add category to product
          final updatedProduct = Product(
            id: product.id,
            name: product.name,
            price: product.price,
            imageUrl: product.imageUrl,
            source: product.source,
            brand: product.brand,
            rating: product.rating,
            description: product.description,
            category: _mapCategory(category),
            reviewCount: product.reviewCount,
            inStock: product.inStock,
          );
          allProducts.add(updatedProduct);
        }
      }

      // Remove duplicates by name
      final uniqueProducts = <Product>[];
      final seenNames = <String>{};
      for (var product in allProducts) {
        if (!seenNames.contains(product.name.toLowerCase())) {
          seenNames.add(product.name.toLowerCase());
          uniqueProducts.add(product);
        }
      }

      print('📊 Fetched ${uniqueProducts.length} unique products from API');

      // Cache products for offline use (max 1000)
      await _cacheService.saveProducts(uniqueProducts);

      // Organize products into categories
      _organizeProducts(uniqueProducts);

      print(
          '✅ Products organized: Featured:${_featuredProducts.length}, Popular:${_popularProducts.length}');
    } catch (e) {
      print('❌ Failed to fetch online products: $e');
      _error = e.toString();
      await _loadFromCache();
    }
  }

  String _mapCategory(String apiCategory) {
    switch (apiCategory.toLowerCase()) {
      case 'laptop':
        return 'Electronics';
      case 'smartphone':
        return 'Electronics';
      case 'headphones':
        return 'Electronics';
      case 'gaming':
        return 'Gaming';
      case 'home':
        return 'Home';
      case 'fashion':
        return 'Fashion';
      default:
        return 'Electronics';
    }
  }

  // Load products from local cache (offline mode)
  Future<void> _loadFromCache() async {
    print('📦 Loading products from local cache...');

    final cachedProducts = await _cacheService.getCachedProducts();

    if (cachedProducts.isNotEmpty) {
      _organizeProducts(cachedProducts);
      print(
          '✅ Loaded ${cachedProducts.length} products from cache (OFFLINE MODE)');
    } else {
      print('⚠️ No cached products found. Please connect to internet first.');
      _error = 'No offline data. Please connect to internet to load products.';
      _featuredProducts = [];
      _popularProducts = [];
      _electronicsProducts = [];
      _gamingProducts = [];
      _homeProducts = [];
      _fashionProducts = [];
    }
  }

  // Refresh products (force fetch from API)
  Future<void> refreshProducts() async {
    print('🔄 Force refreshing products from API...');
    await loadHomeProducts(forceRefresh: true);
  }

  // Organize products into categories
  void _organizeProducts(List<Product> products) {
    // Featured: Top rated products (rating >= 4.5)
    _featuredProducts =
        products.where((p) => (p.rating) >= 4.5).take(10).toList();
    if (_featuredProducts.isEmpty && products.isNotEmpty) {
      _featuredProducts = products.take(10).toList();
    }

    // Popular: First 10 products
    _popularProducts = products.take(10).toList();

    // Electronics
    _electronicsProducts = products
        .where((p) =>
            p.category.toLowerCase().contains('electronic') ||
            p.name.toLowerCase().contains('phone') ||
            p.name.toLowerCase().contains('laptop') ||
            p.name.toLowerCase().contains('headphone'))
        .take(10)
        .toList();

    // Gaming
    _gamingProducts = products
        .where((p) =>
            p.name.toLowerCase().contains('gaming') ||
            p.category.toLowerCase().contains('gaming'))
        .take(10)
        .toList();

    // Home
    _homeProducts = products
        .where((p) =>
            p.category.toLowerCase().contains('home') ||
            p.name.toLowerCase().contains('vacuum') ||
            p.name.toLowerCase().contains('pot'))
        .take(10)
        .toList();

    // Fashion
    _fashionProducts = products
        .where((p) =>
            p.category.toLowerCase().contains('fashion') ||
            p.name.toLowerCase().contains('shoe') ||
            p.name.toLowerCase().contains('nike'))
        .take(10)
        .toList();

    // Fill empty categories with featured products
    if (_electronicsProducts.isEmpty && _featuredProducts.isNotEmpty) {
      _electronicsProducts = _featuredProducts.take(5).toList();
    }
    if (_gamingProducts.isEmpty && _featuredProducts.isNotEmpty) {
      _gamingProducts = _featuredProducts.take(5).toList();
    }
    if (_homeProducts.isEmpty && _featuredProducts.isNotEmpty) {
      _homeProducts = _featuredProducts.take(5).toList();
    }
    if (_fashionProducts.isEmpty && _featuredProducts.isNotEmpty) {
      _fashionProducts = _featuredProducts.take(5).toList();
    }
  }

  // Search products locally (offline)
  List<Product> searchLocally(String query) {
    final allProducts =
        _featuredProducts + _popularProducts + _electronicsProducts;
    return allProducts
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get cache info
  Future<Map<String, dynamic>> getCacheInfo() async {
    return {
      'cacheSize': await _cacheService.getCacheSize(),
      'isOnline': _isOnline,
      'featuredCount': _featuredProducts.length,
      'totalProducts': _featuredProducts.length + _popularProducts.length,
    };
  }
}
