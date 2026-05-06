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

  Future<void> addAlert(Product product, double targetPrice) async {
    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch,
      productId: product.id,
      productName: product.name,
      productUrl: product.productUrl,
      productImage: product.imageUrl,
      targetPrice: targetPrice,
      currentPrice: product.price,
      isNotified: false,
      sourceStore: product.source,
      createdAt: DateTime.now(),
    );

    await _box.put(alert.id.toString(), alert.toJson());
    print('Price alert set for ${product.name} at \$${targetPrice}');
  }

  Future<List<PriceAlert>> getAllAlerts() async {
    final alerts = <PriceAlert>[];
    for (var key in _box.keys) {
      final json = _box.get(key) as Map<String, dynamic>;
      alerts.add(PriceAlert.fromJson(json));
    }
    alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return alerts;
  }

  Future<void> removeAlert(String alertId) async {
    await _box.delete(alertId);
    print('Price alert removed');
  }

  Future<void> updateAlert(PriceAlert alert) async {
    await _box.put(alert.id.toString(), alert.toJson());
  }

  Future<int> getAlertCount() async {
    return _box.length;
  }
}
