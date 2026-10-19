import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_client.dart';
import '../../shared/presentation/order_map.dart';
import '../../shared/presentation/transport_icons.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key, required this.api, required this.token, required this.orderID, this.deliveryCode, this.order});
  final ApiClient api;
  final String token;
  final String orderID;
  final String? deliveryCode;
  final OrderSummary? order;

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Map<String, dynamic>? _location;
  String _state = 'Kurýer gözlenýär';
  String? _deliveryCode;
  bool _loadingCode = false;

  @override
  void initState() { super.initState(); _deliveryCode = widget.deliveryCode; _connect(); }

  Future<void> _refreshCode() async {
    setState(() => _loadingCode = true);
    try { final code = await widget.api.refreshDeliveryOTP(widget.token, widget.orderID); if (mounted) setState(() => _deliveryCode = code); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); }
    finally { if (mounted) setState(() => _loadingCode = false); }
  }

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
      if (mounted) setState(() => _state = 'Kurýer kabul edeninden soň yzarlama açylar');
    } catch (_) {
      if (mounted) setState(() => _state = 'Tracking baglanyşygy açylmady');
    }
  }

  @override
  void dispose() { _subscription?.cancel(); _channel?.sink.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sargydy yzarla')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.order != null) OrderMap(orders: [widget.order!], height: 290) else Container(height: 290, decoration: BoxDecoration(color: const Color(0xFFE8F5F1), borderRadius: BorderRadius.circular(24)), child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.map_outlined, size: 170, color: Color(0xFFB9DED4)),
              if (_location != null) const CircleAvatar(radius: 28, backgroundColor: Color(0xFF0F766E), child: Icon(Icons.local_shipping_rounded, color: Colors.white, size: 30)),
            ])),
            const SizedBox(height: 20),
            Row(children: [const Icon(Icons.local_shipping_rounded, color: Color(0xFF047857)), const SizedBox(width: 8), Expanded(child: Text(_state, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)))]),
            const SizedBox(height: 8),
            Text(_location == null ? 'Kurýer sargydy kabul edende onuň hereketi şu ýerde görkeziler.' : 'Soňky koordinata: ${_location!['latitude']}, ${_location!['longitude']}'),
            if (_deliveryCode != null) ...[
              const SizedBox(height: 18),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Eltiriş OTP kody', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(_deliveryCode!, style: const TextStyle(fontSize: 30, letterSpacing: 8, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('Kody diňe kurýer eltiş nokadyna geleninde aýdyň.')]))),
            ] else ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(onPressed: _loadingCode ? null : _refreshCode, icon: const Icon(Icons.password_rounded), label: Text(_loadingCode ? 'OTP alynýar...' : 'Eltiriş OTP koduny görkez')),
            ],
            const SizedBox(height: 20),
            Card(child: ListTile(leading: widget.order?.courierTransport.isNotEmpty == true ? TransportBadge(transport: widget.order!.courierTransport) : const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(widget.order?.courierName.isNotEmpty == true ? widget.order!.courierName : 'Kurýer maglumatlary'), subtitle: Text(widget.order?.courierName.isNotEmpty == true ? transportLabel(widget.order!.courierTransport) : 'Kurýer kabul edeninden soň ady we ulag görnüşi görkeziler.'))),
            if (widget.order != null) Card(child: ListTile(leading: TransportBadge(transport: widget.order!.transport), title: Text(transportLabel(widget.order!.transport)), subtitle: Text('${widget.order!.pickupAddress} → ${widget.order!.deliveryAddress}', maxLines: 2, overflow: TextOverflow.ellipsis))),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _connect, icon: const Icon(Icons.refresh), label: const Text('Täzeden birikmek'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () => _support(context), icon: const Icon(Icons.support_agent_rounded), label: const Text('Kömek')))]),
          ],
        ),
      );

  void _support(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alyjy jogap bermese ýa-da mesele bolsa, goldaw topary bilen habarlaşyň.')));
}
