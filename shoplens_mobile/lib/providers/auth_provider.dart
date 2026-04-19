import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Initialize auth state from storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');

      if (_accessToken != null) {
        await getCurrentUser();
      }
    } catch (e) {
      print('Initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login - CHANGED parameter name from username to email
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Login provider attempt for: $email');
      final response = await ApiService.login(email, password);

      if (response != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        _accessToken = response['access'];
        _refreshToken = response['refresh'];

        _isLoading = false;
        notifyListeners();
        print('✅ Login provider successful for: ${_user?.username}');
        return true;
      } else {
        // Handle specific error messages
        if (response != null) {
          // Check for email field errors
          if (response['email'] != null) {
            if (response['email'] is List) {
              _error = response['email'][0];
            } else {
              _error = response['email'].toString();
            }
          }
          // Check for non_field_errors
          else if (response['non_field_errors'] != null) {
            if (response['non_field_errors'] is List) {
              _error = response['non_field_errors'][0];
            } else {
              _error = response['non_field_errors'].toString();
            }
          }
          // Check for message
          else if (response['message'] != null) {
            _error = response['message'];
          }
          // Fallback
          else {
            _error = 'Invalid credentials';
          }
        } else {
          _error = 'Login failed - no response from server';
        }

        print('❌ Login provider failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Login provider error: $e');
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
      print('📝 Register provider attempt for: ${userData['email']}');
      final response = await ApiService.register(userData);

      if (response != null && response['user'] != null) {
        _user = User.fromJson(response['user']);
        _accessToken = response['access'];
        _refreshToken = response['refresh'];

        _isLoading = false;
        notifyListeners();
        print('✅ Register provider successful');
        return true;
      } else {
        // Handle specific error messages from backend
        if (response != null) {
          // Check for email errors
          if (response['email'] != null) {
            if (response['email'] is List) {
              _error = response['email'][0];
            } else {
              _error = response['email'].toString();
            }
          }
          // Check for username errors
          else if (response['username'] != null) {
            if (response['username'] is List) {
              _error = response['username'][0];
            } else {
              _error = response['username'].toString();
            }
          }
          // Check for password errors
          else if (response['password'] != null) {
            if (response['password'] is List) {
              _error = response['password'][0];
            } else {
              _error = response['password'].toString();
            }
          }
          // Check for non_field_errors
          else if (response['non_field_errors'] != null) {
            if (response['non_field_errors'] is List) {
              _error = response['non_field_errors'][0];
            } else {
              _error = response['non_field_errors'].toString();
            }
          }
          // Check for message
          else if (response['message'] != null) {
            _error = response['message'];
          }
          // Fallback
          else {
            _error = 'Registration failed';
          }
        } else {
          _error = 'Registration failed - no response from server';
        }

        print('❌ Register provider failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Register provider error: $e');
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

      _isLoading = false;
      notifyListeners();
    }
  }

  // Get current user
  Future<void> getCurrentUser() async {
    try {
      final userData = await ApiService.getCurrentUser();
      if (userData != null) {
        _user = User.fromJson(userData);
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
