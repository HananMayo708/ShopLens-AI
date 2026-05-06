import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/price_alert_model.dart';

class PriceAlertApiService {
  static Future<String> get _baseUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url') ?? 'http://127.0.0.1:8000';
  }

  static Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<PriceAlert>> getPriceAlerts() async {
    try {
      final baseUrl = await _baseUrl;
      final headers = await _headers;

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/price-alerts/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> alertsData = data['alerts'] ?? [];
        return alertsData.map((json) => PriceAlert.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching price alerts: $e');
      return [];
    }
  }

  static Future<bool> createPriceAlert({
    required String productId,
    required String productName,
    required String productUrl,
    required String productImage,
    required double targetPrice,
    required String sourceStore,
  }) async {
    try {
      final baseUrl = await _baseUrl;
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/price-alerts/create/'),
            headers: headers,
            body: json.encode({
              'product_id': productId,
              'product_name': productName,
              'product_url': productUrl,
              'product_image': productImage,
              'target_price': targetPrice,
              'source_store': sourceStore,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating price alert: $e');
      return false;
    }
  }

  static Future<bool> deletePriceAlert(int alertId) async {
    try {
      final baseUrl = await _baseUrl;
      final headers = await _headers;

      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/price-alerts/$alertId/delete/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting price alert: $e');
      return false;
    }
  }
}
