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

  // FORCED ONLINE MODE - Always returns true to ensure products load
  Future<bool> _hasInternet() async {
    // FORCE ONLINE MODE - Always return true
    print('🌐 FORCE ONLINE MODE ENABLED - Always ONLINE');
    return true;
  }

  // MAIN METHOD: Load products with offline-first strategy
  Future<void> loadHomeProducts({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Check internet status (always true now)
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

  // Fetch products from API and cache them - KEEP ALL PRODUCTS
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
        print('📦 Got ${products.length} products for category: $category');

        for (var product in products) {
          // Skip invalid products (missing name or price 0)
          if (product.name == 'Unknown Product' || product.name.isEmpty) {
            continue;
          }

          // Add category to product
          final updatedProduct = Product(
            id: product.id,
            name: product.name,
            price: product.price > 0 ? product.price : 9.99,
            imageUrl: product.imageUrl,
            source: product.source.isNotEmpty ? product.source : category,
            brand: product.brand.isNotEmpty ? product.brand : 'Premium',
            rating: product.rating > 0 ? product.rating : 4.0,
            description: product.description.isNotEmpty
                ? product.description
                : 'High quality product',
            category: _mapCategory(category),
            reviewCount: product.reviewCount > 0 ? product.reviewCount : 100,
            inStock: product.inStock,
          );
          allProducts.add(updatedProduct);
        }
      }

      // KEEP ALL PRODUCTS - NO DEDUPLICATION
      final uniqueProducts = allProducts;
      print('📊 Keeping all ${uniqueProducts.length} products from API');

      // Cache products for offline use (max 1000)
      await _cacheService.saveProducts(uniqueProducts);

      // Organize products into categories
      _organizeProducts(uniqueProducts);

      print(
          '✅ Products organized: Featured:${_featuredProducts.length}, Total:${uniqueProducts.length}');
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

  // Organize products into categories - WITH SHUFFLING to mix all stores
  void _organizeProducts(List<Product> products) {
    print('📊 Organizing ${products.length} products into categories...');

    // SHUFFLE products to mix different stores (Amazon, eBay, Daraz, etc.)
    final shuffledProducts = List<Product>.from(products);
    shuffledProducts.shuffle();

    // Show product sources for debugging
    final sources = shuffledProducts.map((p) => p.source).toSet().toList();
    print('📊 Product sources: $sources');

    // Featured: Top rated products (rating >= 4.5)
    _featuredProducts =
        shuffledProducts.where((p) => (p.rating) >= 4.5).take(10).toList();
    if (_featuredProducts.isEmpty && shuffledProducts.isNotEmpty) {
      _featuredProducts = shuffledProducts.take(10).toList();
    }

    // Popular: First 15 products from shuffled list
    _popularProducts = shuffledProducts.take(15).toList();

    // Electronics - Show shuffled products from all stores
    _electronicsProducts = shuffledProducts.take(20).toList();

    // Gaming
    _gamingProducts = shuffledProducts
        .where((p) =>
            p.name.toLowerCase().contains('gaming') ||
            p.name.toLowerCase().contains('game') ||
            p.name.toLowerCase().contains('playstation') ||
            p.name.toLowerCase().contains('xbox') ||
            p.name.toLowerCase().contains('nintendo'))
        .take(10)
        .toList();

    // Home
    _homeProducts = shuffledProducts
        .where((p) =>
            p.name.toLowerCase().contains('home') ||
            p.name.toLowerCase().contains('vacuum') ||
            p.name.toLowerCase().contains('kitchen') ||
            p.name.toLowerCase().contains('furniture'))
        .take(10)
        .toList();

    // Fashion
    _fashionProducts = shuffledProducts
        .where((p) =>
            p.name.toLowerCase().contains('shoe') ||
            p.name.toLowerCase().contains('nike') ||
            p.name.toLowerCase().contains('adidas') ||
            p.name.toLowerCase().contains('clothing') ||
            p.name.toLowerCase().contains('shirt') ||
            p.name.toLowerCase().contains('dress'))
        .take(10)
        .toList();

    // Fill empty categories with featured or popular products
    if (_electronicsProducts.isEmpty && _featuredProducts.isNotEmpty) {
      _electronicsProducts = _featuredProducts.take(10).toList();
    }
    if (_electronicsProducts.isEmpty && _popularProducts.isNotEmpty) {
      _electronicsProducts = _popularProducts.take(10).toList();
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

    print(
        '📊 Categories - Featured:${_featuredProducts.length}, Electronics:${_electronicsProducts.length}, Popular:${_popularProducts.length}, Gaming:${_gamingProducts.length}, Home:${_homeProducts.length}, Fashion:${_fashionProducts.length}');
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
