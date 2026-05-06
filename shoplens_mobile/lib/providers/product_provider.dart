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

  void addToRecentlyViewed(Product product) {
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    _recentlyViewed.insert(0, product);
    if (_recentlyViewed.length > 20) {
      _recentlyViewed = _recentlyViewed.take(20).toList();
    }
    notifyListeners();
  }

  Future<bool> _hasInternet() async {
    print('🌐 FORCE ONLINE MODE ENABLED - Always ONLINE');
    return true;
  }

  // FIXED: Shows cached products instantly, fetches fresh in background
  Future<void> loadHomeProducts({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // STEP 1: Show cached products IMMEDIATELY (0 seconds)
    await _loadFromCache();

    // STEP 2: Hide loading spinner - user sees products instantly!
    _isLoading = false;
    notifyListeners();

    // STEP 3: Fetch fresh products in BACKGROUND (user doesn't wait)
    _isOnline = await _hasInternet();

    if (_isOnline && !forceRefresh) {
      _fetchOnlineProducts(); // NO AWAIT - runs in background
    } else if (_isOnline && forceRefresh) {
      await _fetchOnlineProducts(); // AWAIT only for force refresh
    }
  }

  Future<void> _fetchOnlineProducts() async {
    print('🌐 Fetching fresh products from API in background...');

    try {
      final categories = [
        'laptop',
        'smartphone',
        'headphones',
        'gaming',
        'home'
      ];
      List<Product> allProducts = [];

      for (String category in categories) {
        final products = await ApiService.searchProducts(category, limit: 50);
        print('📦 Got ${products.length} products for category: $category');

        for (var product in products) {
          if (product.name == 'Unknown Product' || product.name.isEmpty) {
            continue;
          }

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
            productUrl: product.productUrl,
          );
          allProducts.add(updatedProduct);
        }
      }

      if (allProducts.isNotEmpty) {
        await _cacheService.saveProducts(allProducts);
        _organizeProducts(allProducts);
        notifyListeners(); // Update UI with fresh products
        print('✅ UI updated with ${allProducts.length} fresh products');
      }
    } catch (e) {
      print('❌ Failed to fetch online products: $e');
      _error = e.toString();
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

  Future<void> _loadFromCache() async {
    print('📦 Loading products from local cache...');
    final cachedProducts = await _cacheService.getCachedProducts();

    if (cachedProducts.isNotEmpty) {
      _organizeProducts(cachedProducts);
      print('✅ Loaded ${cachedProducts.length} products from cache (INSTANT)');
    } else {
      print('⚠️ No cached products found.');
      _featuredProducts = [];
      _popularProducts = [];
      _electronicsProducts = [];
      _gamingProducts = [];
      _homeProducts = [];
      _fashionProducts = [];
    }
  }

  Future<void> refreshProducts() async {
    print('🔄 Force refreshing products from API...');
    await loadHomeProducts(forceRefresh: true);
  }

  void _organizeProducts(List<Product> products) {
    print('📊 Organizing ${products.length} products into categories...');

    final shuffledProducts = List<Product>.from(products);
    shuffledProducts.shuffle();

    final sources = shuffledProducts.map((p) => p.source).toSet().toList();
    print('📊 Product sources: $sources');

    _featuredProducts =
        shuffledProducts.where((p) => (p.rating) >= 4.5).take(10).toList();
    if (_featuredProducts.isEmpty && shuffledProducts.isNotEmpty) {
      _featuredProducts = shuffledProducts.take(10).toList();
    }

    _popularProducts = shuffledProducts.take(15).toList();
    _electronicsProducts = shuffledProducts.take(20).toList();

    _gamingProducts = shuffledProducts
        .where((p) =>
            p.name.toLowerCase().contains('gaming') ||
            p.name.toLowerCase().contains('game') ||
            p.name.toLowerCase().contains('playstation') ||
            p.name.toLowerCase().contains('xbox') ||
            p.name.toLowerCase().contains('nintendo'))
        .take(10)
        .toList();

    _homeProducts = shuffledProducts
        .where((p) =>
            p.name.toLowerCase().contains('home') ||
            p.name.toLowerCase().contains('vacuum') ||
            p.name.toLowerCase().contains('kitchen') ||
            p.name.toLowerCase().contains('furniture'))
        .take(10)
        .toList();

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

  List<Product> searchLocally(String query) {
    final allProducts =
        _featuredProducts + _popularProducts + _electronicsProducts;
    return allProducts
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<Map<String, dynamic>> getCacheInfo() async {
    return {
      'cacheSize': await _cacheService.getCacheSize(),
      'isOnline': _isOnline,
      'featuredCount': _featuredProducts.length,
      'totalProducts': _featuredProducts.length + _popularProducts.length,
    };
  }
}
