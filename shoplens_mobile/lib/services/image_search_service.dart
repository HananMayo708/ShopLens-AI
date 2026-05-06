import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageSearchService {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  Future<String?> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url') ?? defaultBaseUrl;
  }

  Future<XFile?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    return image;
  }

  Future<XFile?> takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    return image;
  }

  // Main search method - FIXED type handling
  Future<Map<String, dynamic>> searchByImage(XFile image) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/image-search/hybrid/');

      print('📡 Sending image to: $url');

      // Read image bytes
      final bytes = await image.readAsBytes();
      print('📸 Image size: ${bytes.length} bytes');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'search_image.jpg',
        ),
      );

      // Add auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print('⏳ Waiting for response (timeout: 180 seconds)...');

      final response = await request.send().timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw Exception(
              'Request timeout - server not responding after 180 seconds');
        },
      );

      // Read response
      final responseBody = await response.stream.bytesToString();
      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);

        // DEBUG: Print what we received
        print('🔍 API Response Keys: ${data.keys}');

        // SAFELY extract products - ensure it's List, not String
        List<dynamic> products = [];
        String aiDetected = '';
        int total = 0;

        // Check different possible response structures
        if (data['products'] != null && data['products'] is List) {
          products = List<dynamic>.from(data['products']);
          print('✅ Found ${products.length} products in "products" key');
        } else if (data['web_products'] != null &&
            data['web_products'] is List) {
          products = List<dynamic>.from(data['web_products']);
          print('✅ Found ${products.length} products in "web_products" key');
        } else if (data['local_products'] != null &&
            data['local_products'] is List) {
          products = List<dynamic>.from(data['local_products']);
          print('✅ Found ${products.length} products in "local_products" key');
        } else if (data['results'] != null && data['results'] is List) {
          final results = List<dynamic>.from(data['results']);
          products = results.map((r) => r['product'] ?? r).toList();
          print('✅ Found ${products.length} products in "results" key');
        }

        // SAFELY extract ai_detected - ensure it's String, not List
        if (data['ai_detected'] != null && data['ai_detected'] is String) {
          aiDetected = data['ai_detected'] as String;
        } else if (data['detected_product'] != null &&
            data['detected_product'] is String) {
          aiDetected = data['detected_product'] as String;
        } else if (data['search_query'] != null &&
            data['search_query'] is String) {
          aiDetected = data['search_query'] as String;
        } else if (data['detected'] != null && data['detected'] is String) {
          aiDetected = data['detected'] as String;
        } else {
          aiDetected = 'unknown';
        }

        // SAFELY extract total
        if (data['total'] != null && data['total'] is int) {
          total = data['total'] as int;
        } else {
          total = products.length;
        }

        print('🎯 AI Detected: $aiDetected');
        print('📦 Total products found: $total');

        // Print first product for debugging
        if (products.isNotEmpty) {
          final firstProduct = products[0];
          print(
              '📦 Sample product: ${firstProduct['name'] ?? firstProduct['title'] ?? 'No name'}');
          print('   Price: ${firstProduct['price']}');
          print(
              '   Source: ${firstProduct['source'] ?? firstProduct['store'] ?? 'Unknown'}');
        } else {
          print('⚠️ No products found in response');
        }

        return {
          'success': true,
          'products': products,
          'ai_detected': aiDetected,
          'total': total,
        };
      } else {
        print('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'products': <dynamic>[],
          'ai_detected': null,
          'total': 0,
        };
      }
    } catch (e) {
      print('❌ Image search error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'products': <dynamic>[],
        'ai_detected': null,
        'total': 0,
      };
    }
  }

  // Search with more options and longer timeout
  Future<Map<String, dynamic>> searchByImageWithOptions({
    required XFile image,
    int limit = 50,
    String? textQuery,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/image-search/hybrid/');

      print('📡 Sending image to: $url');
      print('📝 Text query: ${textQuery ?? "none"}');
      print('🔢 Limit: $limit');

      final bytes = await image.readAsBytes();
      print('📸 Image size: ${bytes.length} bytes');

      final request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'search_image.jpg',
        ),
      );

      if (textQuery != null && textQuery.isNotEmpty) {
        request.fields['query'] = textQuery;
      }

      request.fields['limit'] = limit.toString();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print('⏳ Waiting for AI to analyze image and search stores...');
      print('   This may take 30-90 seconds for first search');

      final response = await request.send().timeout(
        const Duration(seconds: 240),
        onTimeout: () {
          throw Exception(
              'Search timeout - server took too long to respond. Please try again.');
        },
      );

      final responseBody = await response.stream.bytesToString();
      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);

        print('🔍 API Response Keys: ${data.keys}');

        // Extract products from response
        List<dynamic> products = [];
        String aiDetected = '';
        int total = 0;

        if (data['products'] != null && data['products'] is List) {
          products = List<dynamic>.from(data['products']);
        } else if (data['web_products'] != null &&
            data['web_products'] is List) {
          products = List<dynamic>.from(data['web_products']);
        } else if (data['local_products'] != null &&
            data['local_products'] is List) {
          products = List<dynamic>.from(data['local_products']);
        } else if (data['results'] != null && data['results'] is List) {
          products = List<dynamic>.from(data['results']);
        }

        // Extract ai_detected
        if (data['ai_detected'] != null && data['ai_detected'] is String) {
          aiDetected = data['ai_detected'] as String;
        } else if (data['detected_product'] != null &&
            data['detected_product'] is String) {
          aiDetected = data['detected_product'] as String;
        } else if (data['search_query'] != null &&
            data['search_query'] is String) {
          aiDetected = data['search_query'] as String;
        } else {
          aiDetected = 'unknown';
        }

        // Extract total
        if (data['total'] != null && data['total'] is int) {
          total = data['total'] as int;
        } else {
          total = products.length;
        }

        if (data['processing_time'] != null) {
          print('⏱️ Processing time: ${data['processing_time']} seconds');
        }

        print('🎯 AI Detected: $aiDetected');
        print('📦 Total products: $total');

        return {
          'success': true,
          'products': products,
          'ai_detected': aiDetected,
          'search_query': data['search_query'] ?? aiDetected,
          'total': total,
          'processing_time': data['processing_time'],
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'products': <dynamic>[],
          'ai_detected': null,
          'total': 0,
        };
      }
    } catch (e) {
      print('❌ Image search error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'products': <dynamic>[],
        'ai_detected': null,
        'total': 0,
      };
    }
  }

  // Just recognize image without searching stores (faster)
  Future<Map<String, dynamic>> recognizeImageOnly(XFile image) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/image-search/recognize/');

      print('📡 Sending image for recognition only: $url');

      final bytes = await image.readAsBytes();
      print('📸 Image size: ${bytes.length} bytes');

      final request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'recognize_image.jpg',
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Recognition timeout');
        },
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);

        String detectedProduct = 'unknown';
        double confidence = 0.0;

        if (data['detected_product'] != null &&
            data['detected_product'] is String) {
          detectedProduct = data['detected_product'] as String;
        } else if (data['ai_detected'] != null &&
            data['ai_detected'] is String) {
          detectedProduct = data['ai_detected'] as String;
        }

        if (data['confidence'] != null && data['confidence'] is num) {
          confidence = (data['confidence'] as num).toDouble();
        }

        return {
          'success': true,
          'detected_product': detectedProduct,
          'confidence': confidence,
        };
      } else {
        return {
          'success': false,
          'error': 'Recognition failed: ${response.statusCode}',
          'detected_product': null,
        };
      }
    } catch (e) {
      print('❌ Recognition error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'detected_product': null,
      };
    }
  }
}
