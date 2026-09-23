import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _roleKey = 'role';

  Future<({String token, String role})?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final role = await _storage.read(key: _roleKey);
    if (token == null || role == null) return null;
    return (token: token, role: role);
  }

  Future<void> write(String token, String role) =>
      _storage.write(key: _tokenKey, value: token).then(
        (_) => _storage.write(key: _roleKey, value: role),
      );

  Future<void> clear() => _storage.deleteAll();
}
