import 'package:flutter/material.dart';
import '../models/product_model.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => _items;
  int get count => _items.length;
  bool get hasItems => _items.isNotEmpty;

  bool isInWishlist(Product product) {
    return _items.any((p) => p.id == product.id);
  }

  void addProduct(Product product) {
    if (!isInWishlist(product)) {
      _items.add(product);
      notifyListeners();
    }
  }

  void removeProduct(Product product) {
    _items.removeWhere((p) => p.id == product.id);
    notifyListeners();
  }

  void toggleWishlist(Product product) {
    if (isInWishlist(product)) {
      removeProduct(product);
    } else {
      addProduct(product);
    }
    notifyListeners();
  }
}
