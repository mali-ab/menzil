import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _roleKey = 'role';
  static const _userIDKey = 'user_id';

  Future<({String token, String role, String userID})?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final role = await _storage.read(key: _roleKey);
    if (token == null || role == null) return null;
    return (token: token, role: role, userID: await _storage.read(key: _userIDKey) ?? '');
  }

  Future<void> write(String token, String role, String userID) =>
      _storage.write(key: _tokenKey, value: token).then(
        (_) => _storage.write(key: _roleKey, value: role).then((_) => _storage.write(key: _userIDKey, value: userID)),
      );

  Future<void> clear() => _storage.deleteAll();
}
