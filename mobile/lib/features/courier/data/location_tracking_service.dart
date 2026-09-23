import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_client.dart';

class LocationTrackingService {
  LocationTrackingService(this._api);
  final ApiClient _api;
  WebSocketChannel? _channel;
  StreamSubscription<Position>? _positions;

  bool get isRunning => _positions != null;

  Future<void> start(String token) async {
    if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Geolokasiýa hyzmaty öçürilen');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Geolokasiýa üçin rugsat gerek');
    }
    final uri = _api.baseUri.replace(
      scheme: _api.baseUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/v1/courier/ws/location',
      queryParameters: {'access_token': token},
    );
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;
    _positions = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((position) {
      _channel?.sink.add(jsonEncode({
        'type': 'location', 'latitude': position.latitude, 'longitude': position.longitude,
        'accuracy_m': position.accuracy, 'heading_deg': position.heading, 'speed_mps': position.speed,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      }));
    });
  }

  Future<void> stop() async {
    await _positions?.cancel();
    _positions = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
