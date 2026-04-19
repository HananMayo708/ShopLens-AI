import 'package:hive/hive.dart';
import '../models/price_alert_model.dart';
import '../models/product_model.dart';

class PriceAlertService {
  static const String _alertsBox = 'price_alerts';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_alertsBox);
    print('🔔 Price alerts service initialized with ${_box.length} alerts');
  }

  // Add a new price alert
  Future<void> addAlert(Product product, double targetPrice) async {
    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productName: product.name,
      targetPrice: targetPrice,
      currentPrice: product.price,
      imageUrl: product.imageUrl,
      createdAt: DateTime.now(),
    );
    
    await _box.put(alert.id, alert.toJson());
    print('🔔 Price alert set for ${product.name} at \$${targetPrice}');
  }

  // Get all alerts
  Future<List<PriceAlert>> getAllAlerts() async {
    final alerts = <PriceAlert>[];
    for (var key in _box.keys) {
      final json = _box.get(key) as Map<String, dynamic>;
      alerts.add(PriceAlert.fromJson(json));
    }
    // Sort by creation date (newest first)
    alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return alerts;
  }

  // Remove an alert
  Future<void> removeAlert(String alertId) async {
    await _box.delete(alertId);
    print('🔔 Removed price alert');
  }

  // Update product price and check alerts
  Future<List<PriceAlert>> checkPriceAlerts(List<Product> products) async {
    final triggeredAlerts = <PriceAlert>[];
    final alerts = await getAllAlerts();
    
    for (var alert in alerts) {
      if (alert.isNotified) continue;
      
      // Find matching product
      final product = products.firstWhere(
        (p) => p.id == alert.productId,
        orElse: () => Product(
          id: '',
          name: '',
          price: 0,
          imageUrl: '',
          source: '',
          brand: '',
          rating: 0,
          description: '',
          category: '',
          reviewCount: 0,
          inStock: false,
        ),
      );
      
      if (product.id.isNotEmpty && product.price <= alert.targetPrice && !alert.isNotified) {
        // Price dropped below target!
        alert.isNotified = true;
        await _box.put(alert.id, alert.toJson());
        triggeredAlerts.add(alert);
        print('🎉 PRICE DROP: ${alert.productName} dropped to \$${product.price}');
      }
    }
    
    return triggeredAlerts;
  }

  // Get alert count
  Future<int> getAlertCount() async {
    return _box.length;
  }
}
