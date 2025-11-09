import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userImageKey = 'user_image';

  Future<void> saveToken(String token) async {
    print('StorageService: Saving token...');
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_tokenKey, token);
    print('StorageService: Token saved: $success');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('StorageService: Retrieved token: ${token != null ? "exists" : "null"}');
    return token;
  }

  Future<void> saveUser({
    required int id,
    required String name,
    required String email,
    String? image,
  }) async {
    print('StorageService: Saving user - id: $id, name: $name, email: $email');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, id);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    if (image != null) {
      await prefs.setString(_userImageKey, image);
    }
    print('StorageService: User saved successfully');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userIdKey);
    final name = prefs.getString(_userNameKey);
    final email = prefs.getString(_userEmailKey);

    print('StorageService: Retrieved user - id: $id, name: $name, email: $email');

    if (id == null || name == null || email == null) {
      return null;
    }

    return {
      'id': id,
      'name': name,
      'email': email,
      'image': prefs.getString(_userImageKey),
    };
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userImageKey);
  }
}

