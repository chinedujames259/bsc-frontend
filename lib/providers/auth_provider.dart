import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.getToken();
      if (token != null) {
        final userData = await _storage.getUser();
        if (userData != null) {
          _user = User.fromJson(userData);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Starting sign in...');
      final response = await _apiService.signIn(
        email: email,
        password: password,
      );

      print('AuthProvider: Sign in successful, token: ${response.token.substring(0, 20)}...');
      print('AuthProvider: User: ${response.user.name}, ${response.user.email}');

      await _storage.saveToken(response.token);
      await _storage.saveUser(
        id: response.user.id,
        name: response.user.name,
        email: response.user.email,
        image: response.user.image,
      );

      print('AuthProvider: Token and user saved to storage');

      _user = response.user;
      _error = null;
      print('AuthProvider: User set in provider, isAuthenticated: $isAuthenticated');
    } catch (e) {
      print('AuthProvider: Sign in error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: Sign in completed, loading: $_isLoading, authenticated: $isAuthenticated');
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.signUp(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _storage.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _apiService.getProfile();
      await _storage.saveUser(
        id: user.id,
        name: user.name,
        email: user.email,
        image: user.image,
      );
      _user = user;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
  }
}

