import 'package:flutter/material.dart';
import '../models/stats.dart';
import '../services/api_service.dart';

class StatsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserStats? _stats;
  bool _isLoading = false;
  String? _error;

  UserStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _apiService.getStats();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

