import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pagination;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get pagination => _pagination;

  Future<void> fetchProducts({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getProducts(page: page, limit: limit);
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
}
