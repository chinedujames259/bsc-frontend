import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pagination;
  String? _stockStatus;
  int _lowStockThreshold = 10;
  String _orderBy = 'createdAt';
  String _orderDirection = 'desc';
  bool _isStockUpdating = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get pagination => _pagination;
  String? get stockStatus => _stockStatus;
  int get lowStockThreshold => _lowStockThreshold;
  String get orderBy => _orderBy;
  String get orderDirection => _orderDirection;
  bool get isStockUpdating => _isStockUpdating;

  Future<void> fetchProducts({
    int page = 1,
    int limit = 20,
    String? stockStatus,
    int? lowStockThreshold,
    String? orderBy,
    String? orderDirection,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (stockStatus != null) {
      _stockStatus = stockStatus == 'all' ? null : stockStatus;
    }
    if (lowStockThreshold != null) {
      _lowStockThreshold = lowStockThreshold;
    }
    if (orderBy != null) {
      _orderBy = orderBy;
    }
    if (orderDirection != null) {
      _orderDirection = orderDirection;
    }

    try {
      final result = await _apiService.getProducts(
        page: page,
        limit: limit,
        stockStatus: _stockStatus,
        lowStockThreshold: _stockStatus == 'low_stock' ? _lowStockThreshold : null,
        orderBy: _orderBy,
        orderDirection: _orderDirection,
      );
      _products = result['products'] as List<Product>;
      _pagination = result['pagination'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      _products = [];
      _pagination = null;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.searchProducts(
        query: query.trim(),
        page: page,
        limit: limit,
      );
      _products = result['products'] as List<Product>;
      _pagination = result['pagination'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProduct({
    required String name,
    required String slug,
    required String sku,
    String? description,
    int? stockCount,
    String? price,
    int? categoryId,
    List<String>? imagePaths,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await _apiService.createProduct(
        name: name,
        slug: slug,
        sku: sku,
        description: description,
        stockCount: stockCount,
        price: price,
        categoryId: categoryId,
        imagePaths: imagePaths,
      );
      _products.insert(0, product);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Product? _currentProduct;
  Product? get currentProduct => _currentProduct;

  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProduct = await _apiService.getProductById(id);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _currentProduct = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((product) => product.id == id);
      if (_currentProduct?.id == id) {
        _currentProduct = null;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> adjustProductStock({
    required int productId,
    required bool increase,
    required int amount,
  }) async {
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }

    _isStockUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateProductStock(
        id: productId,
        action: increase ? 'increase' : 'decrease',
        amount: amount,
      );

      final stockCountValue = result['stockCount'];
      final newStockCount = stockCountValue is num
          ? stockCountValue.toInt()
          : int.tryParse(stockCountValue.toString()) ??
              _currentProduct?.stockCount ??
              0;

      if (_currentProduct?.id == productId) {
        _currentProduct = _currentProduct!.copyWith(
          stockCount: newStockCount,
          updatedAt: DateTime.now(),
        );
      }

      final index = _products.indexWhere((product) => product.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          stockCount: newStockCount,
          updatedAt: DateTime.now(),
        );
      }

      return result;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isStockUpdating = false;
      notifyListeners();
    }
  }

  void updateFilters({
    String? stockStatus,
    int? lowStockThreshold,
    String? orderBy,
    String? orderDirection,
  }) {
    var hasChanges = false;

    if (stockStatus != null) {
      final normalizedStatus = stockStatus == 'all' ? null : stockStatus;
      if (_stockStatus != normalizedStatus) {
        _stockStatus = normalizedStatus;
        hasChanges = true;
      }
    }

    if (lowStockThreshold != null && lowStockThreshold > 0) {
      if (_lowStockThreshold != lowStockThreshold) {
        _lowStockThreshold = lowStockThreshold;
        hasChanges = true;
      }
    }

    if (orderBy != null && orderBy.isNotEmpty && _orderBy != orderBy) {
      _orderBy = orderBy;
      hasChanges = true;
    }

    if (orderDirection != null &&
        orderDirection.isNotEmpty &&
        _orderDirection != orderDirection) {
      _orderDirection = orderDirection;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }
}
