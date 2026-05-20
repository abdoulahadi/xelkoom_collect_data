import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  final _storage = const FlutterSecureStorage();

  // Save authentication data
  Future<void> saveAuthData(String token, User user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    await _storage.write(key: _isLoggedInKey, value: 'true');
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get stored user
  Future<User?> getCurrentUser() async {
    final userStr = await _storage.read(key: _userKey);
    if (userStr != null) {
      try {
        final userJson = jsonDecode(userStr);
        return User.fromJson(userJson);
      } catch (e) {
        print('Error deserializing user: $e');
        return null;
      }
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _storage.write(key: _isLoggedInKey, value: 'false');
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }
}
