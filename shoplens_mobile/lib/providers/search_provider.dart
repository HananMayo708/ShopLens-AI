import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product_model.dart';
import '../services/api_service.dart';

class SearchProvider extends ChangeNotifier {
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String? _currentQuery;
  String? _aiDetectedLabels;
  String? _searchedImageBase64; // NEW: Store the searched image

  // Getters
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentQuery => _currentQuery;
  String? get aiDetectedLabels => _aiDetectedLabels;
  String? get searchedImageBase64 => _searchedImageBase64; // NEW getter

  // Clear results
  void clearResults() {
    _searchResults = [];
    _error = null;
    _currentQuery = null;
    _aiDetectedLabels = null;
    _searchedImageBase64 = null; // NEW: Clear searched image
    notifyListeners();
  }

  // Search products using text query
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) return;

    // Update state
    _isLoading = true;
    _error = null;
    _currentQuery = query;
    _aiDetectedLabels = null;
    _searchedImageBase64 = null; // NEW: Clear searched image for text search
    notifyListeners();

    try {
      print('🔍 SearchProvider: Searching for "$query"');

      // Call the correct ApiService method (direct RapidAPI endpoint)
      final results = await ApiService.searchProducts(query);

      // Update results
      _searchResults = results;
      _isLoading = false;

      print('✅ SearchProvider: Found ${results.length} products');
      notifyListeners();
    } catch (e) {
      print('❌ SearchProvider error: $e');
      _error = e.toString();
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
    }
  }

  // NEW: Set image search results with searched image
  void setImageSearchResults(
      List<Product> results, String? aiLabels, String? searchedImageBase64) {
    _searchResults = results;
    _aiDetectedLabels = aiLabels;
    _currentQuery = '📷 Image Search';
    _isLoading = false;
    _error = null;
    _searchedImageBase64 = searchedImageBase64; // NEW: Store the image
    notifyListeners();
  }

  // Load more products (pagination) - if needed
  Future<void> loadMoreProducts() async {
    // Implement pagination if your API supports it
  }

  // Refresh current search
  Future<void> refreshSearch() async {
    if (_currentQuery != null && _currentQuery!.isNotEmpty) {
      if (_aiDetectedLabels != null) {
        // If it was an image search, just keep results
        return;
      }
      await searchProducts(_currentQuery!);
    }
  }
}
