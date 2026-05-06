import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user initials for avatar
  String get userInitials => _user?.initials ?? '?';

  // Get display name
  String get displayName => _user?.fullName ?? _user?.username ?? 'Guest';

  // Constructor - load saved session immediately
  AuthProvider() {
    _loadSavedSession();
  }

  // Load saved session from local storage
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final userJson = prefs.getString('user_data');

      if (_accessToken != null && userJson != null) {
        try {
          final Map<String, dynamic> userMap = json.decode(userJson);
          _user = User.fromJson(userMap);
          print('✅ Auto-login successful for: ${_user?.email}');
          notifyListeners();
        } catch (e) {
          print('❌ Failed to parse saved user data: $e');
          await _clearStorage();
        }
      } else {
        print('📭 No saved session found');
      }
    } catch (e) {
      print('❌ Error loading saved session: $e');
    }
  }

  // Save session to local storage
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString('access_token', _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString('refresh_token', _refreshToken!);
      }
      if (_user != null) {
        await prefs.setString('user_data', json.encode(_user!.toJson()));
      }
      print('✅ Session saved to local storage');
    } catch (e) {
      print('❌ Failed to save session: $e');
    }
  }

  // Clear storage on logout
  Future<void> _clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');
      print('🗑️ Storage cleared');
    } catch (e) {
      print('❌ Failed to clear storage: $e');
    }
  }

  // Initialize auth state (called from main)
  Future<void> initialize() async {
    // Session already loaded in constructor
    // This method is kept for compatibility
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Login attempt for: $email');
      final response = await ApiService.login(email, password);

      if (response != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        _accessToken = response['access'];
        _refreshToken = response['refresh'];

        // Save to local storage
        await _saveSession();

        _isLoading = false;
        notifyListeners();
        print('✅ Login successful for: ${_user?.username}');
        return true;
      } else {
        if (response != null) {
          if (response['email'] != null) {
            _error = response['email'] is List
                ? response['email'][0]
                : response['email'].toString();
          } else if (response['non_field_errors'] != null) {
            _error = response['non_field_errors'] is List
                ? response['non_field_errors'][0]
                : response['non_field_errors'].toString();
          } else if (response['message'] != null) {
            _error = response['message'];
          } else {
            _error = 'Invalid credentials';
          }
        } else {
          _error = 'Login failed - no response from server';
        }

        print('❌ Login failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 Register attempt for: ${userData['email']}');
      final response = await ApiService.register(userData);

      if (response != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        _accessToken = response['access'];
        _refreshToken = response['refresh'];

        // Save to local storage
        await _saveSession();

        _isLoading = false;
        notifyListeners();
        print('✅ Register successful');
        return true;
      } else {
        if (response != null) {
          if (response['email'] != null) {
            _error = response['email'] is List
                ? response['email'][0]
                : response['email'].toString();
          } else if (response['username'] != null) {
            _error = response['username'] is List
                ? response['username'][0]
                : response['username'].toString();
          } else if (response['password'] != null) {
            _error = response['password'] is List
                ? response['password'][0]
                : response['password'].toString();
          } else if (response['non_field_errors'] != null) {
            _error = response['non_field_errors'] is List
                ? response['non_field_errors'][0]
                : response['non_field_errors'].toString();
          } else if (response['message'] != null) {
            _error = response['message'];
          } else {
            _error = 'Registration failed';
          }
        } else {
          _error = 'Registration failed - no response from server';
        }

        print('❌ Register failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Register error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _user = null;
      _accessToken = null;
      _refreshToken = null;
      _error = null;

      // Clear local storage
      await _clearStorage();

      _isLoading = false;
      notifyListeners();
      print('✅ Logout successful');
    }
  }

  // Get current user
  Future<void> getCurrentUser() async {
    try {
      final userData = await ApiService.getCurrentUser();
      if (userData != null) {
        _user = User.fromJson(userData);
        await _saveSession(); // Update stored user data
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await ApiService.updateProfile(data);
      if (updatedUser != null) {
        _user = User.fromJson(updatedUser);
        await _saveSession(); // Update stored user data
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final response = await ApiService.refreshToken();
      if (response != null) {
        _accessToken = response['access'];
        await _saveSession(); // Update stored token
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Refresh token error: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await ApiService.changePassword(oldPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
