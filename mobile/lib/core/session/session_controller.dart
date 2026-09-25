import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

enum SessionState { loading, unauthenticated, authenticated }

class SessionController extends ChangeNotifier {
  SessionController(this._api, this._storage) {
    restore();
  }

  final ApiClient _api;
  final TokenStorage _storage;
  SessionState state = SessionState.loading;
  String? token;
  String? role;
  String? userID;

  Future<void> restore() async {
    final saved = await _storage.read();
    if (saved != null) {
      token = saved.token;
      role = saved.role;
      userID = saved.userID;
      state = SessionState.authenticated;
    } else {
      state = SessionState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    final response = await _api.login(phone: phone, password: password);
    await _set(response);
  }

  Future<void> register({
    required String phone,
    required String name,
    required String password,
    required String role,
    String? transport,
  }) async {
    final response = await _api.register(
      phone: phone,
      fullName: name,
      password: password,
      role: role,
      transport: transport,
    );
    await _set(response);
  }

  Future<void> _set(AuthResponse response) async {
    token = response.token;
    role = response.role;
    state = SessionState.authenticated;
    userID = response.userID;
    await _storage.write(response.token, response.role, response.userID);
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clear();
    token = null;
    role = null;
    userID = null;
    state = SessionState.unauthenticated;
    notifyListeners();
  }
}
