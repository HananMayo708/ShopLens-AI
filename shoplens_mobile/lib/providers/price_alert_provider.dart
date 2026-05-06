import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/price_alert_api_service.dart';
import '../models/price_alert_model.dart';

class PriceAlertProvider extends ChangeNotifier {
  List<PriceAlert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<PriceAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _alerts.length;

  PriceAlertProvider() {
    _loadLocalAlerts();
  }

  Future<void> _loadLocalAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString('price_alerts');

      if (alertsJson != null) {
        final List<dynamic> decoded = json.decode(alertsJson);
        _alerts = decoded.map((item) => PriceAlert.fromJson(item)).toList();
        debugPrint(
            '✅ Loaded ${_alerts.length} price alerts from local storage');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to load price alerts: $e');
    }

    await syncWithServer();
  }

  Future<void> _saveLocalAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = json.encode(_alerts.map((a) => a.toJson()).toList());
      await prefs.setString('price_alerts', alertsJson);
      debugPrint('💾 Saved ${_alerts.length} price alerts to local storage');
    } catch (e) {
      debugPrint('❌ Failed to save price alerts: $e');
    }
  }

  // ✅ CORRECT WAY: Create alert with named parameters
  Future<bool> createAlert({
    required String productId,
    required String productName,
    required double targetPrice,
    String productUrl = '',
    String productImage = '',
    String sourceStore = 'Amazon',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final alert = PriceAlert(
        id: 0,
        productId: productId,
        productName: productName,
        productUrl: productUrl,
        productImage: productImage,
        targetPrice: targetPrice,
        currentPrice: 0,
        isNotified: false,
        sourceStore: sourceStore,
        createdAt: DateTime.now(),
      );

      final created = await PriceAlertApiService.createPriceAlert(alert);
      if (created != null) {
        _alerts.add(created);
        await _saveLocalAlerts();
        notifyListeners();
        debugPrint('✅ Price alert created for: $productName');
        return true;
      }
      _error = 'Failed to create alert';
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Failed to create alert: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Alternative: Add existing alert object
  Future<bool> addAlert(PriceAlert alert) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await PriceAlertApiService.createPriceAlert(alert);
      if (created != null) {
        _alerts.add(created);
        await _saveLocalAlerts();
        notifyListeners();
        debugPrint('✅ Price alert added: ${alert.productName}');
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Failed to add alert: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAlert(int alertId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await PriceAlertApiService.deletePriceAlert(alertId);
      if (success) {
        _alerts.removeWhere((a) => a.id == alertId);
        await _saveLocalAlerts();
        notifyListeners();
        debugPrint('✅ Price alert deleted: $alertId');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Failed to delete alert: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncWithServer() async {
    try {
      final serverAlerts = await PriceAlertApiService.getPriceAlerts();
      if (serverAlerts.isNotEmpty) {
        _alerts = serverAlerts;
        await _saveLocalAlerts();
        notifyListeners();
        debugPrint('✅ Synced ${_alerts.length} alerts from server');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync alerts from server: $e');
    }
  }

  Future<void> refreshAlerts() async {
    await syncWithServer();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
