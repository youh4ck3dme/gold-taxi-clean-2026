import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'local_storage_service.dart';

class SecureStorageService implements LocalStorageService {
  final FlutterSecureStorage _storage;
  final Logger _logger = Logger();

  static const String _tokenKey = 'auth_token';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Get authentication token
  @override
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      _logger.e('Error reading token: $e');
      return null;
    }
  }

  /// Save authentication token
  @override
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      _logger.i('Token saved successfully');
    } catch (e) {
      _logger.e('Error saving token: $e');
    }
  }

  /// Delete authentication token
  @override
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      _logger.i('Token deleted successfully');
    } catch (e) {
      _logger.e('Error deleting token: $e');
    }
  }
}
