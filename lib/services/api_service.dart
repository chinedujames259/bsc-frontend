import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/stats.dart';
import '../models/order.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/signin');

      print('Attempting sign in to: $url');

      final response = await http
          .post(
            url,
            headers: await _getHeaders(),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(AppConfig.connectionTimeout);

      print('Sign in response status: ${response.statusCode}');
      print('Sign in response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed sign in data: $data');
        return AuthResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ??
              'Sign in failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Sign in error: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/signup');

    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Sign up failed');
    }
  }

  Future<User> getProfile() async {
    final url = Uri.parse('${AppConfig.baseUrl}/profile');

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch profile');
    }
  }

  Future<List<Category>> getCategories() async {
    final url = Uri.parse('${AppConfig.baseUrl}/categories');

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((category) => Category.fromJson(category)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch categories');
    }
  }

  Future<Category> createCategory(String name) async {
    final url = Uri.parse('${AppConfig.baseUrl}/categories');

    final response = await http.post(
      url,
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Category.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create category');
    }
  }

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 10,
    String? stockStatus,
    int? lowStockThreshold,
    String? orderBy,
    String? orderDirection,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (stockStatus != null && stockStatus.isNotEmpty) 'stockStatus': stockStatus,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold.toString(),
      if (orderBy != null && orderBy.isNotEmpty) 'orderBy': orderBy,
      if (orderDirection != null && orderDirection.isNotEmpty)
        'orderDirection': orderDirection,
    };

    final url = Uri.parse('${AppConfig.baseUrl}/products')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final products = (data['products'] as List)
          .map((product) => Product.fromJson(product))
          .toList();

      return {'products': products, 'pagination': data['pagination']};
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch products');
    }
  }

  Future<Map<String, dynamic>> updateProductStock({
    required int id,
    required String action,
    required int amount,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/products/$id/stock');

    final response = await http.patch(
      url,
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({'action': action, 'amount': amount}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update product stock');
    }
  }

  Future<Map<String, dynamic>> searchProducts({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      '${AppConfig.baseUrl}/products/search?q=$encodedQuery&page=$page&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final products = (data['products'] as List)
          .map((product) => Product.fromJson(product))
          .toList();

      return {
        'products': products,
        'pagination': data['pagination'],
        'searchTerm': data['searchTerm'] ?? query,
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to search products');
    }
  }

  Future<Product> createProduct({
    required String name,
    required String slug,
    required String sku,
    String? description,
    int? stockCount,
    String? price,
    int? categoryId,
    List<String>? imagePaths,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/products');
    final token = await _storage.getToken();

    var request = http.MultipartRequest('POST', url);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.fields['slug'] = slug;
    request.fields['sku'] = sku;
    if (description != null) request.fields['description'] = description;
    if (stockCount != null)
      request.fields['stockCount'] = stockCount.toString();
    if (price != null) request.fields['price'] = price;
    if (categoryId != null)
      request.fields['categoryId'] = categoryId.toString();

    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (var imagePath in imagePaths) {
        var file = await http.MultipartFile.fromPath('images', imagePath);
        request.files.add(file);
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create product');
    }
  }

  Future<Product> getProductById(int id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/products/$id');

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch product');
    }
  }

  Future<void> deleteProduct(int id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/products/$id');

    final response = await http.delete(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete product');
    }
  }

  Future<UserStats> getStats() async {
    final url = Uri.parse('${AppConfig.baseUrl}/stats');

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserStats.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch stats');
    }
  }

  Future<Map<String, dynamic>> getOrders({int page = 1, int limit = 10}) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/orders?page=$page&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final orders = (data['orders'] as List)
          .map((order) => Order.fromJson(order))
          .toList();

      return {'orders': orders, 'pagination': data['pagination']};
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch orders');
    }
  }

  Future<Order> createOrder(List<Map<String, dynamic>> items) async {
    final url = Uri.parse('${AppConfig.baseUrl}/orders');

    final response = await http.post(
      url,
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({'items': items}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create order');
    }
  }

  Future<Order> getOrderById(int id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/orders/$id');

    final response = await http.get(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch order');
    }
  }

  Future<Order> updateOrderStatus(int id, String status) async {
    final url = Uri.parse('${AppConfig.baseUrl}/orders/$id');

    final response = await http.patch(
      url,
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update order status');
    }
  }

  Future<void> deleteOrder(int id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/orders/$id');

    final response = await http.delete(
      url,
      headers: await _getHeaders(includeAuth: true),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete order');
    }
  }
}
