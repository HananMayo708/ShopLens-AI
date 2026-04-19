import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';

class CompareProvider extends ChangeNotifier {
  Product? _product1;
  Product? _product2;
  Map<String, dynamic>? _matchingResult;
  List<Product> _allProducts = [];
  Map<String, List<Product>> _groupedProducts = {};
  bool _isLoading = false;
  String? _error;
  String _selectedView = 'grouped';
  int _retryCount = 0;

  // ✅ Cache for seller verification data from backend
  final Map<String, Map<String, dynamic>> _verificationCache = {};

  // ── Getters ───────────────────────────────────────────────────────
  Product? get product1 => _product1;
  Product? get product2 => _product2;
  Map<String, dynamic>? get matchingResult => _matchingResult;
  List<Product> get allProducts => _allProducts;
  Map<String, List<Product>> get groupedProducts => _groupedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedView => _selectedView;

  // ── Local fallback data for offline use ──────────────────────────
  static const Map<String, Map<String, dynamic>> _localFallback = {
    'amazon': {
      'storeName': 'Amazon',
      'isVerified': true,
      'isTrusted': true,
      'trustScore': 95,
      'yearsInBusiness': 26,
      'returnsPolicy': '30-day free returns',
      'shippingSpeed': '1-2 days (Prime)',
      'badges': ['Official Retailer', 'Prime Shipping', 'A-to-Z Guarantee'],
      'sellerRating': 'A+',
      'verificationStatus': 'Verified',
    },
    'walmart': {
      'storeName': 'Walmart',
      'isVerified': true,
      'isTrusted': true,
      'trustScore': 92,
      'yearsInBusiness': 22,
      'returnsPolicy': '90-day free returns',
      'shippingSpeed': '2-3 days',
      'badges': ['Official Store', 'Free Returns', 'Price Match'],
      'sellerRating': 'A+',
      'verificationStatus': 'Verified',
    },
    'best buy': {
      'storeName': 'Best Buy',
      'isVerified': true,
      'isTrusted': true,
      'trustScore': 91,
      'yearsInBusiness': 30,
      'returnsPolicy': '15-day returns',
      'shippingSpeed': '2-3 days',
      'badges': ['Authorized Dealer', 'Geek Squad'],
      'sellerRating': 'A',
      'verificationStatus': 'Verified',
    },
    'target': {
      'storeName': 'Target',
      'isVerified': true,
      'isTrusted': true,
      'trustScore': 90,
      'yearsInBusiness': 24,
      'returnsPolicy': '90-day returns',
      'shippingSpeed': '2-4 days',
      'badges': ['Official Store', 'Free Returns'],
      'sellerRating': 'A',
      'verificationStatus': 'Verified',
    },
    'ebay': {
      'storeName': 'eBay',
      'isVerified': true,
      'isTrusted': false,
      'trustScore': 82,
      'yearsInBusiness': 28,
      'returnsPolicy': 'Varies by seller',
      'shippingSpeed': '3-7 days',
      'badges': ['Buyer Protection', 'Money Back'],
      'sellerRating': 'B+',
      'verificationStatus': 'Registered',
    },
    'newegg': {
      'storeName': 'Newegg',
      'isVerified': true,
      'isTrusted': true,
      'trustScore': 88,
      'yearsInBusiness': 23,
      'returnsPolicy': '30-day returns',
      'shippingSpeed': '2-4 days',
      'badges': ['Tech Specialist', 'Authorized Dealer'],
      'sellerRating': 'A',
      'verificationStatus': 'Verified',
    },
  };

  // ── Get seller verification (API first, fallback to local) ────────
  Map<String, dynamic> getSellerVerification(Product product) {
    final source = product.source ?? 'Unknown';
    final key = source.toLowerCase().trim();

    // Return cached result if available
    if (_verificationCache.containsKey(key)) {
      return _verificationCache[key]!;
    }

    // Try local fallback immediately for known stores
    for (final entry in _localFallback.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        _verificationCache[key] = Map<String, dynamic>.from(entry.value);
        return _verificationCache[key]!;
      }
    }

    // Return default for unknown stores
    final defaultData = {
      'storeName': source,
      'isVerified': false,
      'isTrusted': false,
      'trustScore': 60,
      'yearsInBusiness': 3,
      'returnsPolicy': 'Check seller policy',
      'shippingSpeed': '5-10 days',
      'badges': ['Unverified'],
      'sellerRating': 'C',
      'verificationStatus': 'Unverified',
    };
    _verificationCache[key] = defaultData;
    return defaultData;
  }

  // ── Fetch verification from backend API ───────────────────────────
  Future<void> fetchSellerVerifications(List<String> storeNames) async {
    try {
      final uniqueStores = storeNames.toSet().toList();
      final uncached = uniqueStores
          .where((s) => !_verificationCache.containsKey(s.toLowerCase()))
          .toList();

      if (uncached.isEmpty) return;

      print('🔍 Fetching verification for: $uncached');
      final results = await ApiService.verifyMultipleSellers(uncached);

      if (results != null) {
        results.forEach((storeName, data) {
          _verificationCache[storeName.toLowerCase()] =
              Map<String, dynamic>.from(data);
        });
        print('✅ Cached verification for ${results.length} stores');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error fetching seller verifications: $e');
    }
  }

  // ── Helper methods ────────────────────────────────────────────────
  Color getSellerBadgeColor(Product product) {
    final v = getSellerVerification(product);
    final status = v['verificationStatus'] ?? 'Unverified';
    if (status == 'Verified') return Colors.green;
    if (status == 'Registered') return Colors.orange;
    return Colors.grey;
  }

  String getSellerBadgeText(Product product) {
    final v = getSellerVerification(product);
    final status = v['verificationStatus'] ?? 'Unverified';
    if (status == 'Verified') return 'Verified';
    if (status == 'Registered') return 'Registered';
    return 'Unverified';
  }

  bool isSellerVerified(Product product) {
    return getSellerVerification(product)['isVerified'] ?? false;
  }

  bool isSellerTrusted(Product product) {
    return getSellerVerification(product)['isTrusted'] ?? false;
  }

  int getTrustScore(Product product) {
    return getSellerVerification(product)['trustScore'] ?? 60;
  }

  String getReturnsPolicy(Product product) {
    return getSellerVerification(product)['returnsPolicy'] ?? 'Unknown';
  }

  String getShippingSpeed(Product product) {
    return getSellerVerification(product)['shippingSpeed'] ?? 'Unknown';
  }

  List<String> getSellerBadges(Product product) {
    final v = getSellerVerification(product);
    final badges = v['badges'];
    if (badges is List) return List<String>.from(badges);
    return [];
  }

  String getSellerRating(Product product) {
    return getSellerVerification(product)['sellerRating'] ?? 'C';
  }

  // ── Original single-product methods ──────────────────────────────
  void selectProduct1(Product product) {
    _product1 = product;
    notifyListeners();
  }

  void selectProduct2(Product product) {
    _product2 = product;
    notifyListeners();
  }

  void clearSelection() {
    _product1 = null;
    _product2 = null;
    _matchingResult = null;
    _error = null;
    notifyListeners();
  }

  Future<void> compareProducts() async {
    if (_product1 == null || _product2 == null) {
      _error = 'Please select two products to compare';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _matchingResult = await ApiService.compareProducts([
        _product1!.id,
        _product2!.id,
      ]);
      if (_matchingResult == null) {
        _error = 'Comparison failed';
      }
    } catch (e) {
      _error = e.toString();
      _matchingResult = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double? get comparisonScore {
    if (_matchingResult == null) return null;
    return (_matchingResult!['score'] ?? 0).toDouble();
  }

  Map<String, dynamic>? get comparisonDetails => _matchingResult?['details'];

  void resetComparison() {
    _matchingResult = null;
    _error = null;
    notifyListeners();
  }

  void setSelectedView(String view) {
    _selectedView = view;
    notifyListeners();
  }

  void addProduct(Product product) {
    if (!_allProducts.any((p) => p.id == product.id)) {
      _allProducts.add(product);
      _groupProducts();
      notifyListeners();
    }
  }

  bool isInComparison(Product product) {
    return _allProducts.any((p) => p.id == product.id);
  }

  void removeProduct(Product product) {
    _allProducts.removeWhere((p) => p.id == product.id);
    _groupProducts();
    notifyListeners();
  }

  void clearComparison() {
    _allProducts.clear();
    _groupedProducts.clear();
    notifyListeners();
  }

  // ── Load products with seller verification ────────────────────────
  Future<void> loadProductsForComparison() async {
    _isLoading = true;
    _error = null;
    _retryCount = 0;
    notifyListeners();
    await _fetchProductsWithRetry();
  }

  Future<void> _fetchProductsWithRetry() async {
    try {
      print(
          '🔄 [${DateTime.now()}] Loading products for comparison... (Attempt ${_retryCount + 1})');

      const categories = [
        'laptop',
        'smartphone',
        'electronics',
        'headphones',
        'tablet'
      ];
      print('📋 Categories to fetch: $categories');

      final futures = categories.map((cat) => _fetchCategoryWithFallback(cat));
      final results = await Future.wait(futures);

      final allProducts = <Product>[];
      for (int i = 0; i < results.length; i++) {
        allProducts.addAll(results[i]);
        print('📦 Category ${categories[i]}: ${results[i].length} products');
      }

      print('📊 Total products before grouping: ${allProducts.length}');

      if (allProducts.isEmpty) {
        if (_retryCount < 2) {
          _retryCount++;
          await Future.delayed(const Duration(seconds: 2));
          await _fetchProductsWithRetry();
          return;
        } else {
          _error = 'No products available. Please check your connection.';
        }
      }

      _allProducts = allProducts;
      _groupProducts();

      // ✅ Fetch real seller verification from backend
      final storeNames = _allProducts
          .map((p) => p.source ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      await fetchSellerVerifications(storeNames);

      print(
          '✅ Total: ${_allProducts.length} products → ${_groupedProducts.length} comparable groups');
    } catch (e) {
      print('❌ Failed to load products: $e');
      if (_retryCount < 2) {
        _retryCount++;
        await Future.delayed(const Duration(seconds: 3));
        await _fetchProductsWithRetry();
      } else {
        _error = 'Failed to load products: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Product>> _fetchCategoryWithFallback(String category) async {
    try {
      final products = await ApiService.searchProducts(category);
      if (products.isNotEmpty) return products;
      return [];
    } catch (e) {
      print('❌ Error fetching $category: $e');
      return [];
    }
  }

  void _groupProducts() {
    final raw = <String, List<Product>>{};

    for (final product in _allProducts) {
      final key = _normalizeProductName(product.name);
      raw.putIfAbsent(key, () => []);
      raw[key]!.add(product);
    }

    for (final products in raw.values) {
      products.sort((a, b) => a.price.compareTo(b.price));
    }

    final multiStore = <String, List<Product>>{};
    raw.forEach((key, products) {
      if (products.isNotEmpty) {
        multiStore[key] = products.take(5).toList();
      }
    });

    final sorted = multiStore.entries.toList()
      ..sort((a, b) {
        final aMin =
            a.value.map((p) => p.price).reduce((x, y) => x < y ? x : y);
        final bMin =
            b.value.map((p) => p.price).reduce((x, y) => x < y ? x : y);
        return aMin.compareTo(bMin);
      });

    _groupedProducts = Map.fromEntries(sorted);
    print('📊 Grouped into ${_groupedProducts.length} groups');
  }

  String _normalizeProductName(String name) {
    String n = name.toLowerCase();
    n = n.replaceAll(RegExp(r'[^\w\s]'), ' ');
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();

    const stop = {
      'the',
      'and',
      'with',
      'for',
      'by',
      'from',
      'new',
      'latest',
      'best',
      'top',
      '2024',
      '2025',
      '2026',
      'official',
      'original',
      'genuine',
      'black',
      'white',
      'silver',
      'gold',
      'space',
      'gray',
      'grey',
      'inch',
      'inches',
      'gb',
      'tb',
      'ram',
      'ssd',
      'hdd',
      'series',
      'model',
      'edition',
      'version',
      'plus',
      'pro',
      'max',
      'ultra',
      'lite',
      'air'
    };

    final words = n
        .split(' ')
        .where((w) => w.length > 1 && !stop.contains(w))
        .take(5)
        .toList();

    return words.join(' ').trim();
  }

  double getBestPriceForGroup(List<Product> products) {
    if (products.isEmpty) return 0;
    return products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  Map<String, double> getPriceRangeForGroup(List<Product> products) {
    if (products.isEmpty) return {'min': 0, 'max': 0};
    final min = products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final max = products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    return {'min': min, 'max': max};
  }

  double getAveragePriceForGroup(List<Product> products) {
    if (products.isEmpty) return 0;
    return products.fold(0.0, (s, p) => s + p.price) / products.length;
  }

  Product? getBestImageProduct(List<Product> products) {
    for (final p in products) {
      if (p.imageUrl != null &&
          p.imageUrl!.isNotEmpty &&
          !p.imageUrl!.contains('placeholder')) {
        return p;
      }
    }
    return products.isNotEmpty ? products.first : null;
  }

  Set<String> getAllStores() {
    final stores = <String>{};
    for (final products in _groupedProducts.values) {
      for (final p in products) {
        if (p.source != null && p.source!.isNotEmpty) stores.add(p.source!);
      }
    }
    return stores;
  }

  Map<String, List<Product>> filterGroupsBySearch(String query) {
    if (query.isEmpty) return _groupedProducts;
    final q = query.toLowerCase();
    return Map.fromEntries(
      _groupedProducts.entries.where((e) =>
          e.key.contains(q) ||
          e.value.any((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.brand?.toLowerCase().contains(q) ?? false))),
    );
  }

  Future<void> refreshProducts() => loadProductsForComparison();

  void clearAllData() {
    _product1 = null;
    _product2 = null;
    _matchingResult = null;
    _allProducts = [];
    _groupedProducts = {};
    _error = null;
    notifyListeners();
  }

  Map<String, dynamic> getStats() {
    final uniqueStores = <String>{};
    for (final p in _allProducts) {
      if (p.source != null && p.source!.isNotEmpty) uniqueStores.add(p.source!);
    }
    return {
      'totalProducts': _allProducts.length,
      'totalGroups': _groupedProducts.length,
      'uniqueStores': uniqueStores.length,
      'stores': uniqueStores.toList(),
    };
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      _isLoading = true;
      notifyListeners();
      final products = await ApiService.searchProducts(query);
      return products;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> compareTwoProducts(
      Product p1, Product p2) async {
    _product1 = p1;
    _product2 = p2;
    await compareProducts();
    return _matchingResult;
  }
}
