import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_client.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key, required this.api, required this.token, required this.orderID, this.deliveryCode});
  final ApiClient api;
  final String token;
  final String orderID;
  final String? deliveryCode;

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Map<String, dynamic>? _location;
  String _state = 'Kurýere garaşylýar';

  @override
  void initState() { super.initState(); _connect(); }

  Future<void> _connect() async {
    final uri = widget.api.baseUri.replace(
      scheme: widget.api.baseUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/v1/orders/${widget.orderID}/tracking/ws',
      queryParameters: {'access_token': widget.token},
    );
    try {
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _subscription = channel.stream.listen((message) {
        final value = jsonDecode(message as String) as Map<String, dynamic>;
        if (value['type'] == 'location') setState(() { _location = value; _state = 'Kurýer hereket edýär'; });
      }, onError: (_) { if (mounted) setState(() => _state = 'Baglanyşyk kesildi'); });
      if (mounted) setState(() => _state = 'Kurýeriň pozisiýasyna garaşylýar');
    } catch (_) {
      if (mounted) setState(() => _state = 'Tracking baglanyşygy açylmady');
    }
  }

  @override
  void dispose() { _subscription?.cancel(); _channel?.sink.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sargydy yzarla')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 290, decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(28)), child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.map_outlined, size: 170, color: Color(0xFFC7D2FE)),
              if (_location != null) const CircleAvatar(radius: 28, backgroundColor: Color(0xFF4F46E5), child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 30)),
            ])),
            const SizedBox(height: 20),
            Text(_state, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_location == null ? 'Kurýer sargydy kabul edende onuň hereketi şu ýerde görkeziler.' : 'Soňky koordinata: ${_location!['latitude']}, ${_location!['longitude']}'),
            if (widget.deliveryCode != null) ...[
              const SizedBox(height: 18),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Eltiriş OTP kody', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(widget.deliveryCode!, style: const TextStyle(fontSize: 30, letterSpacing: 8, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('Kody diňe kurýer eltiş nokadyna geleninde aýdyň.')]))),
            ],
            const Spacer(),
            OutlinedButton.icon(onPressed: _connect, icon: const Icon(Icons.refresh), label: const Text('Täzeden birikmek')),
          ]),
        ),
      );
}
