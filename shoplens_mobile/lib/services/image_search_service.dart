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
      
      print('⏳ Waiting for response...');
      
      // Send request with timeout
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server not responding');
        },
      );
      
      // Read response
      final responseBody = await response.stream.bytesToString();
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        return {
          'success': true,
          'local_products': data['local_products'] ?? [],
          'web_products': data['web_products'] ?? [],
          'ai_detected': data['ai_detected'],
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Image search error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
