import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient(this.baseUri, {http.Client? client}) : _client = client ?? http.Client();

  factory ApiClient.fromEnvironment() {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    return ApiClient(Uri.parse(url));
  }

  final Uri baseUri;
  final http.Client _client;

  Uri _uri(String path) => baseUri.replace(path: '/v1$path');

  Future<AuthResponse> login({required String phone, required String password}) async {
    final json = await _request('POST', '/auth/login', body: {
      'phone': phone,
      'password': password,
    });
    return AuthResponse(json['access_token'] as String, json['role'] as String);
  }

  Future<AuthResponse> register({
    required String phone,
    required String fullName,
    required String password,
    required String role,
    String? transport,
  }) async {
    final json = await _request('POST', '/auth/register', body: {
      'phone': phone,
      'full_name': fullName,
      'password': password,
      'role': role,
      if (transport != null) 'transport': transport,
    });
    return AuthResponse(json['access_token'] as String, json['role'] as String);
  }

  Future<String> createOrder(String token, Map<String, Object> payload) async {
    final json = await _request('POST', '/orders', token: token, body: payload);
    return json['id'] as String;
  }

  Future<List<OrderSummary>> availableOrders(String token) async {
    final json = await _request('GET', '/courier/orders/available', token: token);
    return _ordersFrom(json);
  }

  Future<List<OrderSummary>> activeOrders(String token) async =>
      _ordersFrom(await _request('GET', '/courier/orders/active', token: token));

  List<OrderSummary> _ordersFrom(Map<String, dynamic> json) =>
      (json['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .toList();

  Future<void> acceptOrder(String token, String id) =>
      _request('POST', '/courier/orders/$id/accept', token: token);

  Future<void> changeStatus(String token, String id, String status) =>
      _request('POST', '/courier/orders/$id/status', token: token, body: {'status': status});

  Future<void> setAvailability(String token, bool value) =>
      _request('PUT', '/courier/availability', token: token, body: {'is_available': value});

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    String? token,
    Map<String, Object>? body,
  }) async {
    final headers = <String, String>{
      'content-type': 'application/json',
      'accept': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await _client.get(_uri(path), headers: headers),
      'POST' => await _client.post(_uri(path), headers: headers, body: encodedBody),
      'PUT' => await _client.put(_uri(path), headers: headers, body: encodedBody),
      _ => throw UnsupportedError('HTTP usuly goldanylmaýar: $method'),
    };
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded['error'] as String? ?? 'Serwer säwligi');
    }
    return decoded;
  }
}

class AuthResponse {
  const AuthResponse(this.token, this.role);
  final String token;
  final String role;
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.number,
    required this.title,
    required this.weightKg,
    required this.status,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.price,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: json['id'] as String,
        number: json['public_number'] as int,
        title: json['title'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        status: json['status'] as String,
        pickupAddress: json['pickup_address'] as String,
        pickupLatitude: (json['pickup_latitude'] as num).toDouble(),
        pickupLongitude: (json['pickup_longitude'] as num).toDouble(),
        deliveryAddress: json['delivery_address'] as String,
        deliveryLatitude: (json['delivery_latitude'] as num).toDouble(),
        deliveryLongitude: (json['delivery_longitude'] as num).toDouble(),
        price: (json['price_amount'] as num).toDouble(),
      );

  final String id;
  final int number;
  final String title;
  final double weightKg;
  final String status;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final double price;
}
