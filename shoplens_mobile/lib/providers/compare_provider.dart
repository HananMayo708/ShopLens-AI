import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';

// ProductMatchGroup class - defined once here
class ProductMatchGroup {
  final String productName;
  final List<Product> products;
  String representativeImage;
  Product bestPriceProduct;
  Product worstPriceProduct;
  PriceRange priceRange;
  int storeCount;

  ProductMatchGroup({
    required this.productName,
    required this.products,
    required this.representativeImage,
    required this.bestPriceProduct,
    required this.worstPriceProduct,
    required this.priceRange,
    required this.storeCount,
  });
}

class PriceRange {
  final double min;
  final double max;

  const PriceRange({required this.min, required this.max});
}

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

  // Cache for seller verification data
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

  // ── Smart Product Matching Methods ────────────────────────────────

  /// Get matched products grouped by actual product (across different platforms)
  List<ProductMatchGroup> getMatchedProducts(String searchQuery) {
    final Map<String, ProductMatchGroup> matches = {};

    for (final product in _allProducts) {
      final baseName = _getProductBaseName(product.name);

      if (!matches.containsKey(baseName)) {
        matches[baseName] = ProductMatchGroup(
          productName: baseName,
          products: [],
          representativeImage: product.imageUrl ?? '',
          bestPriceProduct: product,
          worstPriceProduct: product,
          priceRange: PriceRange(min: product.price, max: product.price),
          storeCount: 0,
        );
      }

      matches[baseName]!.products.add(product);

      // Update best price
      if (product.price < matches[baseName]!.bestPriceProduct.price) {
        matches[baseName]!.bestPriceProduct = product;
      }

      // Update worst price
      if (product.price > matches[baseName]!.worstPriceProduct.price) {
        matches[baseName]!.worstPriceProduct = product;
      }

      // Update price range
      matches[baseName]!.priceRange = PriceRange(
        min: matches[baseName]!
            .products
            .map((p) => p.price)
            .reduce((a, b) => a < b ? a : b),
        max: matches[baseName]!
            .products
            .map((p) => p.price)
            .reduce((a, b) => a > b ? a : b),
      );

      matches[baseName]!.storeCount = matches[baseName]!.products.length;

      // Update best image
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        matches[baseName]!.representativeImage = product.imageUrl!;
      }
    }

    // Filter by search query
    var filtered = matches.values.toList();
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      filtered = filtered
          .where((group) =>
              group.productName.toLowerCase().contains(lowerQuery) ||
              group.products
                  .any((p) => p.name.toLowerCase().contains(lowerQuery)))
          .toList();
    }

    // Sort by best price (cheapest first)
    filtered.sort(
        (a, b) => a.bestPriceProduct.price.compareTo(b.bestPriceProduct.price));

    return filtered;
  }

  /// Get comparison statistics
  Map<String, dynamic> getComparisonStats() {
    final matchedGroups = getMatchedProducts('');
    final allPrices = _allProducts.map((p) => p.price).toList();
    final bestPrice =
        allPrices.isNotEmpty ? allPrices.reduce((a, b) => a < b ? a : b) : 0;
    final bestPriceProduct = _allProducts.firstWhere(
      (p) => p.price == bestPrice,
      orElse: () => _allProducts.isNotEmpty
          ? _allProducts.first
          : Product(
              id: '',
              name: '',
              price: 0,
              imageUrl: '',
              source: '',
              brand: '',
              rating: 0,
              description: '',
            ),
    );

    return {
      'totalProducts': _allProducts.length,
      'totalMatches': matchedGroups.length,
      'bestPriceStore': bestPriceProduct.source ?? 'Unknown',
      'bestPrice': bestPrice,
    };
  }

  /// Get maximum savings for a group of products
  double getMaxSavings(List<Product> products) {
    if (products.length < 2) return 0;
    final prices = products.map((p) => p.price).toList();
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    return maxPrice - minPrice;
  }

  /// Get price range for a group
  Map<String, double> getPriceRangeForGroup(List<Product> products) {
    if (products.isEmpty) return {'min': 0, 'max': 0};
    final min = products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final max = products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    return {'min': min, 'max': max};
  }

  /// Get best price for a group
  double getBestPriceForGroup(List<Product> products) {
    if (products.isEmpty) return 0;
    return products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  /// Get shipping estimate
  String getShippingEstimate(Product product) {
    final source = product.source?.toLowerCase() ?? '';
    if (source.contains('amazon')) return 'Prime 2-day';
    if (source.contains('ebay')) return '3-5 days';
    if (source.contains('daraz')) return '2-4 days';
    if (source.contains('walmart')) return '2-3 days';
    if (source.contains('aliexpress')) return '7-15 days';
    return 'Standard';
  }

  /// Get shipping speed (alias for getShippingEstimate)
  String getShippingSpeed(Product product) {
    return getShippingEstimate(product);
  }

  /// Get returns policy
  String getReturnsPolicy(Product product) {
    final source = product.source?.toLowerCase() ?? '';
    if (source.contains('amazon')) return '30 days';
    if (source.contains('walmart')) return '90 days';
    if (source.contains('ebay')) return '14 days';
    if (source.contains('daraz')) return '7 days';
    return '30 days';
  }

  /// Get availability
  String getAvailability(Product product) {
    return product.inStock ? 'In Stock' : 'Out of Stock';
  }

  /// Check if product has best price in its group
  bool isBestPriceForProduct(Product product) {
    final groups = getMatchedProducts('');
    final group = groups.firstWhere(
      (g) => g.products.any((p) => p.id == product.id),
      orElse: () => ProductMatchGroup(
        productName: '',
        products: [product],
        representativeImage: '',
        bestPriceProduct: product,
        worstPriceProduct: product,
        priceRange: PriceRange(min: product.price, max: product.price),
        storeCount: 1,
      ),
    );
    return group.bestPriceProduct.id == product.id;
  }

  /// Get top products for side-by-side comparison (one per store)
  List<Product> getTopProductsForComparison() {
    final Map<String, Product> bestFromStore = {};
    for (final product in _allProducts) {
      final store = product.source ?? 'Unknown';
      if (!bestFromStore.containsKey(store) ||
          product.price < bestFromStore[store]!.price) {
        bestFromStore[store] = product;
      }
    }
    return bestFromStore.values.toList();
  }

  /// Extract base product name (remove specifications) - IMPROVED VERSION
  String _getProductBaseName(String fullName) {
    String cleaned = fullName.toLowerCase();

    // Remove brand names that appear at the beginning
    final brandPatterns = [
      r'^apple\s+',
      r'^samsung\s+',
      r'^sony\s+',
      r'^lg\s+',
      r'^hp\s+',
      r'^dell\s+',
      r'^lenovo\s+',
      r'^asus\s+',
      r'^acer\s+',
      r'^microsoft\s+',
      r'^google\s+',
      r'^oneplus\s+',
      r'^xiaomi\s+',
      r'^realme\s+',
      r'^oppo\s+',
      r'^vivo\s+',
      r'^nokia\s+',
      r'^motorola\s+',
      r'^huawei\s+',
      r'^amazon\s+',
    ];

    for (final pattern in brandPatterns) {
      cleaned = cleaned.replaceFirst(RegExp(pattern, caseSensitive: false), '');
    }

    // Remove common specifications
    final removePatterns = [
      r'\([^)]*\)', // (something)
      r'\[[^\]]*\]', // [something]
      r'\b\d+\s*gb\b', // 64GB
      r'\b\d+\s*tb\b', // 1TB
      r'\b\d+\s*ram\b', // 8GB RAM
      r'\b\d+[x×]\d+\b', // 1920x1080
      r'\bv[\d.]+\b', // v1.0
      r'\bgen\s?\d+\b', // gen 2
      r'\bversion\s?\d+\b', // version 2
      r'\b\d+\s*%\b', // 100%
      r'\bnew\b', // new
      r'\bused\b', // used
      r'\brefurbished\b', // refurbished
      r'\bwireless\b', // wireless
      r'\bbluetooth\b', // bluetooth
      r'\bwith\s+\w+\b', // with something
      r'\band\s+\w+\b', // and something
      r'\bfor\s+\w+\b', // for something
      r'\bhigh[- ]quality\b', // high quality
      r'\bbest[- ]seller\b', // best seller
      r'\btop[- ]rated\b', // top rated
      r'\blich\b', // inch
      r'\binch\b', // inch
      r'\bcm\b', // cm
      r'\bmm\b', // mm
      r'\bkg\b', // kg
      r'\bg\b', // g
      r'\bpack\s+of\b', // pack of
      r'\bset\s+of\b', // set of
    ];

    for (final pattern in removePatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }

    // Replace common words with shorter forms for better matching
    final replacements = {
      'smartphone': 'phone',
      'headphone': 'earphone',
      'notebook': 'laptop',
      'ultrabook': 'laptop',
      'tablet': 'tab',
      'cellular phone': 'phone',
      'mobile phone': 'phone',
      'cell phone': 'phone',
    };

    for (final entry in replacements.entries) {
      cleaned = cleaned.replaceAll(
          RegExp(r'\b' + entry.key + r'\b', caseSensitive: false), entry.value);
    }

    // Remove extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Get core product name (first 3-5 meaningful words)
    final words = cleaned.split(' ').where((w) => w.length > 2).toList();

    if (words.length > 5) {
      cleaned = words.take(5).join(' ');
    }

    // Remove trailing color words
    cleaned = cleaned.replaceAll(
        RegExp(
            r'\s+(black|white|silver|gold|space|gray|grey|blue|red|green|pink|purple)$'),
        '');

    // Remove trailing common words
    cleaned = cleaned.replaceAll(
        RegExp(r'\s+(version|edition|model|series|generation)$'), '');

    // If result is too short, return original truncated
    if (cleaned.length < 5 && fullName.length > 20) {
      return fullName.substring(0, 50);
    }

    return cleaned.isNotEmpty
        ? cleaned
        : fullName.substring(0, fullName.length.clamp(0, 60));
  }

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
    'daraz': {
      'storeName': 'Daraz.pk',
      'isVerified': true,
      'isTrusted': true,
      'trustScore': 88,
      'yearsInBusiness': 10,
      'returnsPolicy': '7-day returns',
      'shippingSpeed': '2-4 days',
      'badges': ['Official Marketplace', 'Free Shipping'],
      'sellerRating': 'A-',
      'verificationStatus': 'Verified',
    },
    'aliexpress': {
      'storeName': 'AliExpress',
      'isVerified': true,
      'isTrusted': false,
      'trustScore': 78,
      'yearsInBusiness': 14,
      'returnsPolicy': '15-day returns',
      'shippingSpeed': '7-20 days',
      'badges': ['Buyer Protection', 'Global Shipping'],
      'sellerRating': 'B',
      'verificationStatus': 'Registered',
    },
  };

  // ── Get seller verification (API first, fallback to local) ────────
  Map<String, dynamic> getSellerVerification(Product product) {
    final source = product.source ?? 'Unknown';
    final key = source.toLowerCase().trim();

    if (_verificationCache.containsKey(key)) {
      return _verificationCache[key]!;
    }

    for (final entry in _localFallback.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        _verificationCache[key] = Map<String, dynamic>.from(entry.value);
        return _verificationCache[key]!;
      }
    }

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

  // ── Helper methods for seller verification ────────────────────────
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

  List<String> getSellerBadges(Product product) {
    final v = getSellerVerification(product);
    final badges = v['badges'];
    if (badges is List) return List<String>.from(badges);
    return [];
  }

  String getSellerRating(Product product) {
    return getSellerVerification(product)['sellerRating'] ?? 'C';
  }

  // ── Product Comparison Methods ────────────────────────────────────
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

  // ── Product List Management ───────────────────────────────────────
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

  // ── Load Products from API ────────────────────────────────────────
  Future<void> loadProductsForComparison() async {
    _isLoading = true;
    _error = null;
    _retryCount = 0;
    notifyListeners();
    await _fetchProductsWithRetry();
  }

  Future<void> _fetchProductsWithRetry() async {
    try {
      const categories = [
        'laptop',
        'smartphone',
        'electronics',
        'headphones',
        'tablet'
      ];
      final futures = categories.map((cat) => _fetchCategoryWithFallback(cat));
      final results = await Future.wait(futures);

      final allProducts = <Product>[];
      for (final products in results) {
        allProducts.addAll(products);
      }

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
    } catch (e) {
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
      return await ApiService.searchProducts(category);
    } catch (e) {
      return [];
    }
  }

  void _groupProducts() {
    final raw = <String, List<Product>>{};

    for (final product in _allProducts) {
      final key = _getProductBaseName(product.name);

      // Also try a more aggressive match for products that might be the same
      String altKey = key;
      if (key.contains('phone')) {
        altKey = 'smartphone';
      } else if (key.contains('tab')) {
        altKey = 'tablet';
      } else if (key.contains('earphone') || key.contains('headphone')) {
        altKey = 'headphones';
      }

      raw.putIfAbsent(key, () => []);
      if (!raw[key]!.any((p) => p.id == product.id)) {
        raw[key]!.add(product);
      }

      // Also add to alternative key if different
      if (altKey != key) {
        raw.putIfAbsent(altKey, () => []);
        if (!raw[altKey]!.any((p) => p.id == product.id)) {
          raw[altKey]!.add(product);
        }
      }
    }

    // Sort products within each group by price
    for (final products in raw.values) {
      products.sort((a, b) => a.price.compareTo(b.price));
    }

    // Keep all groups, even single-store ones, but prioritize multi-store groups
    final multiStore = <String, List<Product>>{};
    final sortedEntries = raw.entries.toList()
      ..sort((a, b) {
        // Prioritize groups with more stores
        if (a.value.length != b.value.length) {
          return b.value.length.compareTo(a.value.length);
        }
        // Then by best price
        final aMin =
            a.value.map((p) => p.price).reduce((x, y) => x < y ? x : y);
        final bMin =
            b.value.map((p) => p.price).reduce((x, y) => x < y ? x : y);
        return aMin.compareTo(bMin);
      });

    for (final entry in sortedEntries) {
      multiStore[entry.key] = entry.value;
    }

    _groupedProducts = multiStore;
    print('📊 Grouped into ${_groupedProducts.length} groups');
    for (final entry in _groupedProducts.entries) {
      if (entry.value.length > 1) {
        print('   ${entry.key}: ${entry.value.length} stores');
      }
    }
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
