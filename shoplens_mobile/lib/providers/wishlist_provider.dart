import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../services/api_service.dart';

class WishlistProvider extends ChangeNotifier {
  List<Product> _items = [];
  bool _isLoading = false;

  List<Product> get items => _items;
  int get count => _items.length;
  bool get hasItems => _items.isNotEmpty;
  bool get isLoading => _isLoading;

  // Constructor - load saved wishlist
  WishlistProvider() {
    _loadSavedWishlist();
  }

  // Load wishlist from local storage
  Future<void> _loadSavedWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString('wishlist');

      if (wishlistJson != null) {
        try {
          final List<dynamic> decoded = json.decode(wishlistJson);
          _items = decoded.map((item) => Product.fromJson(item)).toList();
          print('✅ Loaded ${_items.length} products from local wishlist');
          notifyListeners();
        } catch (e) {
          print('❌ Failed to parse wishlist: $e');
        }
      } else {
        print('📭 No saved wishlist found');
      }
    } catch (e) {
      print('❌ Error loading wishlist: $e');
    }
  }

  // Save wishlist to local storage
  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = json.encode(_items.map((p) => p.toJson()).toList());
      await prefs.setString('wishlist', wishlistJson);
      print('💾 Wishlist saved to local storage (${_items.length} items)');
    } catch (e) {
      print('❌ Failed to save wishlist: $e');
    }
  }

  // Check if product is in wishlist
  bool isInWishlist(Product product) {
    return _items.any((p) => p.id == product.id);
  }

  // Add product to wishlist
  Future<void> addProduct(Product product) async {
    if (!isInWishlist(product)) {
      _items.add(product);
      await _saveWishlist();
      notifyListeners();
      print('✅ Added to wishlist: ${product.name}');

      // Sync with server in background
      _syncWithServer();
    }
  }

  // Remove product from wishlist
  Future<void> removeProduct(Product product) async {
    _items.removeWhere((p) => p.id == product.id);
    await _saveWishlist();
    notifyListeners();
    print('🗑️ Removed from wishlist: ${product.name}');

    // Sync with server in background
    _syncWithServer();
  }

  // Toggle wishlist status
  Future<void> toggleWishlist(Product product) async {
    if (isInWishlist(product)) {
      await removeProduct(product);
    } else {
      await addProduct(product);
    }
  }

  // Sync wishlist with server
  Future<void> _syncWithServer() async {
    try {
      // For each item, ensure it exists on server
      for (final product in _items) {
        await ApiService.addToWishlist(product.id);
      }
      print('✅ Wishlist synced with server');
    } catch (e) {
      print('⚠️ Failed to sync wishlist with server: $e');
    }
  }

  // Load wishlist from server (overwrites local)
  Future<void> syncFromServer() async {
    _isLoading = true;
    notifyListeners();

    try {
      final serverWishlist = await ApiService.getWishlist();
      if (serverWishlist != null && serverWishlist.isNotEmpty) {
        _items = serverWishlist;
        await _saveWishlist();
        print('✅ Wishlist synced from server (${_items.length} items)');
      }
    } catch (e) {
      print('❌ Failed to sync wishlist from server: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear entire wishlist
  Future<void> clearWishlist() async {
    _items.clear();
    await _saveWishlist();
    notifyListeners();
    print('🗑️ Wishlist cleared');

    // Sync with server
    try {
      for (final product in _items) {
        await ApiService.removeFromWishlist(product.id);
      }
    } catch (e) {
      print('⚠️ Failed to clear wishlist on server: $e');
    }
  }
}
