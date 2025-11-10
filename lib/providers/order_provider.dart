import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pagination;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get pagination => _pagination;

  Future<void> fetchOrders({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getOrders(page: page, limit: limit);
      _orders = result['orders'] as List<Order>;
      _pagination = result['pagination'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order> createOrder(List<Map<String, dynamic>> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _apiService.createOrder(items);
      _orders.insert(0, order);
      return order;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Order? _currentOrder;
  Order? get currentOrder => _currentOrder;

  Future<void> fetchOrderById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentOrder = await _apiService.getOrderById(id);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _currentOrder = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order> getOrderById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _apiService.getOrderById(id);
      return order;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(int id, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOrder = await _apiService.updateOrderStatus(id, status);
      final index = _orders.indexWhere((order) => order.id == id);
      if (index >= 0) {
        _orders[index] = updatedOrder;
      }
      if (_currentOrder?.id == id) {
        _currentOrder = updatedOrder;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteOrder(id);
      _orders.removeWhere((order) => order.id == id);
      if (_currentOrder?.id == id) {
        _currentOrder = null;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
