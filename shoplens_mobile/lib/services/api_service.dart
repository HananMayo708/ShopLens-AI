import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import 'server_discovery.dart';

class ApiService {
  static String? _baseUrl;
  static bool _isDiscovering = false;

  // Dynamic base URL with auto-discovery
  static Future<String> get baseUrl async {
    if (_baseUrl == null && !_isDiscovering) {
      _baseUrl = await ServerDiscovery.getServerUrl();
    }
    return '$_baseUrl/api';
  }

  // Reset base URL (useful when network changes)
  static Future<void> resetBaseUrl() async {
    await ServerDiscovery.resetServerUrl();
    _baseUrl = null;
    print('🔄 API base URL reset');
  }

  // ========== TOKEN MANAGEMENT ==========

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========== CREDENTIAL STORAGE ==========

  static Future<void> saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      print('✅ Credentials saved locally');
    } catch (e) {
      print('❌ Error saving credentials: $e');
    }
  }

  static Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('saved_email');
    } catch (e) {
      print('❌ Error getting saved email: $e');
      return null;
    }
  }

  static Future<String?> getSavedPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('saved_password');
    } catch (e) {
      print('❌ Error getting saved password: $e');
      return null;
    }
  }

  static Future<void> clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      print('✅ Credentials cleared');
    } catch (e) {
      print('❌ Error clearing credentials: $e');
    }
  }

  // ========== AUTHENTICATION METHODS ==========

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final url = await baseUrl;
      print('🔐 Login attempt for: $email');
      print('🌐 Server: $url/auth/login/');

      final response = await http
          .post(
            Uri.parse('$url/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Login response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await saveTokens(data['access'], data['refresh']);
        print('✅ Login successful');
        return data;
      } else {
        print('❌ Login failed: ${response.body}');
        try {
          return json.decode(response.body);
        } catch (e) {
          return {'message': 'Login failed with status ${response.statusCode}'};
        }
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> register(
      Map<String, dynamic> userData) async {
    try {
      final url = await baseUrl;
      print('📝 Register attempt for: ${userData['email']}');
      print('🌐 Server: $url/auth/register/');

      final response = await http
          .post(
            Uri.parse('$url/auth/register/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(userData),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Register response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await saveTokens(data['access'], data['refresh']);
        print('✅ Registration successful');
        return data;
      } else {
        print('❌ Registration failed: ${response.body}');
        try {
          return json.decode(response.body);
        } catch (e) {
          return {
            'message': 'Registration failed with status ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      print('❌ Register error: $e');
      return {'message': 'Network error: $e'};
    }
  }

  static Future<void> logout() async {
    try {
      final url = await baseUrl;
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        await http.post(
          Uri.parse('$url/auth/logout/'),
          headers: await getHeaders(),
          body: json.encode({'refresh': refreshToken}),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await clearTokens();
      await clearSavedCredentials();
      print('👋 Logged out');
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final url = await baseUrl;
      final token = await getAccessToken();
      if (token == null) return null;

      final response = await http
          .get(
            Uri.parse('$url/auth/profile/'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Get current user error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final url = await baseUrl;
      final response = await http
          .patch(
            Uri.parse('$url/auth/profile/'),
            headers: await getHeaders(),
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Update profile error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> refreshToken() async {
    try {
      final url = await baseUrl;
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http
          .post(
            Uri.parse('$url/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refresh': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Refresh token error: $e');
      return null;
    }
  }

  static Future<bool> changePassword(
      String oldPassword, String newPassword) async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse('$url/auth/change-password/'),
            headers: await getHeaders(),
            body: json.encode({
              'old_password': oldPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Change password error: $e');
      return false;
    }
  }

  // ========== PRODUCT METHODS ==========

  // PRIMARY: Multi-Store Search (Real-time data from 5+ websites in parallel)
  static Future<List<Product>> searchProducts(String query,
      {int limit = 20}) async {
    try {
      final url = await baseUrl;
      final token = await getAccessToken();
      if (token == null) return [];

      print('🔍 Multi-Store searching for: "$query"');
      final searchUrl = '$url/multistore/search/?q=$query&limit=$limit';
      print('📡 URL: $searchUrl');

      // Increased timeout for parallel searches (60 seconds is enough for parallel)
      final response = await http
          .get(
            Uri.parse(searchUrl),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 90));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> productsData = jsonData['products'] ?? [];
        print('📦 Products data count: ${productsData.length}');

        List<Product> products = [];
        for (var item in productsData) {
          try {
            Map<String, dynamic> productMap;
            if (item is Map<String, dynamic>) {
              productMap = item;
            } else if (item is Map) {
              productMap = Map<String, dynamic>.from(item);
            } else {
              continue;
            }

            String productName = productMap['name']?.toString() ??
                productMap['product_title']?.toString() ??
                'Unknown Product';

            if (productName.isEmpty || productName == 'Unknown Product') {
              continue;
            }

            double price = 0.0;
            if (productMap['price'] != null) {
              if (productMap['price'] is num) {
                price = (productMap['price'] as num).toDouble();
              } else if (productMap['price'] is String) {
                String priceStr = productMap['price'].toString();
                priceStr = priceStr
                    .replaceAll('Rs.', '')
                    .replaceAll(',', '')
                    .replaceAll('\$', '')
                    .trim();
                price = double.tryParse(priceStr) ?? 0.0;
              }
            }

            if (price <= 0) {
              price = 19.99;
            }

            String imageUrl = productMap['image_url']?.toString() ?? '';
            String source = productMap['source']?.toString() ?? 'Store';
            double rating = productMap['rating'] is num
                ? (productMap['rating'] as num).toDouble()
                : 4.0;
            int reviewCount = productMap['review_count'] is num
                ? (productMap['review_count'] as num).toInt()
                : 0;
            String productId = productMap['id']?.toString() ??
                productMap['itemId']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString();
            String description = productMap['description']?.toString() ??
                'No description available';

            final product = Product(
              id: productId,
              name: productName,
              price: price,
              imageUrl: imageUrl,
              source: source,
              brand: 'Generic',
              rating: rating,
              description: description,
              category: 'Electronics',
              reviewCount: reviewCount,
              inStock: true,
            );
            products.add(product);
          } catch (e) {
            print('⚠️ Error parsing product: $e');
          }
        }

        print(
            '✅ Successfully parsed ${products.length} products from Multi-Store');
        return products;
      } else {
        print('❌ Error response: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }

  // BACKUP: ScraperAPI Search (Fallback)
  static Future<List<Product>> searchScraperAPI(String query,
      {int limit = 20}) async {
    try {
      final url = await baseUrl;
      final token = await getAccessToken();
      if (token == null) return [];

      print('🔍 ScraperAPI (backup) searching for: "$query"');
      final searchUrl = '$url/scraperapi/search/?q=$query&limit=$limit';
      print('📡 URL: $searchUrl');

      final response = await http
          .get(
            Uri.parse(searchUrl),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> productsData = jsonData['products'] ?? [];

        return productsData.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ ScraperAPI search error: $e');
      return [];
    }
  }

  static Future<List<Product>> getTrendingProducts() async {
    try {
      final url = await baseUrl;
      final response = await http
          .get(
            Uri.parse('$url/rapidapi/trending/'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> trendingData = jsonData['trending'] ?? [];

        List<Product> products = [];
        for (var item in trendingData) {
          try {
            products.add(Product.fromJson(Map<String, dynamic>.from(item)));
          } catch (e) {
            print('⚠️ Error parsing trending product: $e');
          }
        }
        return products;
      }
      return [];
    } catch (e) {
      print('❌ Trending error: $e');
      return [];
    }
  }

  static Future<Product?> getProductDetails(String productId) async {
    try {
      final url = await baseUrl;
      final response = await http
          .get(
            Uri.parse('$url/product/$productId/'),
            headers: await getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Details error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> compareProducts(
      List<String> productIds) async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse('$url/compare/'),
            headers: await getHeaders(),
            body: json.encode({'product_ids': productIds}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Compare error: $e');
      return null;
    }
  }

  // ========== SELLER VERIFICATION ==========

  static Future<Map<String, dynamic>?> verifySeller(String storeName) async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse('$url/seller/verify/'),
            headers: await getHeaders(),
            body: json.encode({'store_name': storeName}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['verification'];
      }
      return null;
    } catch (e) {
      print('❌ Seller verification error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> verifyMultipleSellers(
      List<String> storeNames) async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse('$url/seller/verify-multiple/'),
            headers: await getHeaders(),
            body: json.encode({'store_names': storeNames}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'];
      }
      return null;
    } catch (e) {
      print('❌ Multiple seller verification error: $e');
      return null;
    }
  }

  // ========== INTERNET CONNECTION CHECK ==========

  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
