import 'package:flutter/material.dart';

import '../../../core/maps/map_navigation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../shared/presentation/app_widgets.dart';
import '../data/location_tracking_service.dart';

class CourierHomePage extends StatefulWidget {
  const CourierHomePage({super.key, required this.session, required this.api});
  final SessionController session;
  final ApiClient api;
  @override
  State<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends State<CourierHomePage> {
  late final LocationTrackingService _tracking;
  List<OrderSummary> _orders = [];
  bool _available = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _tracking = LocationTrackingService(widget.api); _load(); }
  @override
  void dispose() { _tracking.stop(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { _orders = await widget.api.availableOrders(widget.session.token!); }
    catch (error) { _error = error.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _availability(bool value) async {
    try {
      await widget.api.setAvailability(widget.session.token!, value);
      if (value) { await _tracking.start(widget.session.token!); }
      else { await _tracking.stop(); }
      if (mounted) setState(() => _available = value);
      if (value) await _load();
    } catch (error) { if (mounted) showError(context, error); }
  }

  Future<void> _accept(OrderSummary order) async {
    try {
      await widget.api.acceptOrder(widget.session.token!, order.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sargyt kabul edildi')));
      await _load();
    } catch (error) { if (mounted) showError(context, error); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(actions: [IconButton(onPressed: widget.session.logout, icon: const Icon(Icons.logout_rounded))]),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            AppGradientHeader(title: _available ? 'Siz setirde' : 'Soňkyra setire çykyň', subtitle: _available ? 'Geopozisiýa iberilýär' : 'Sargytlary görmek üçin elýeterli boluň.', icon: _available ? Icons.gps_fixed : Icons.pause_circle_outline),
            const SizedBox(height: 18),
            Card(child: SwitchListTile.adaptive(
              value: _available,
              onChanged: _availability,
              secondary: Icon(_available ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: _available ? Colors.green : Colors.grey),
              title: const Text('Elýeterli', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(_available ? 'Täze sargytlar açyk' : 'Soňkyra sargytlar gizlin'),
            )),
            const SizedBox(height: 24),
            Text('Laýyk sargytlar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (_loading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(_error!)))
            else if (!_available) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Soňkyra çykanyňyzda ulag görnüşiňize laýyk sargytlar görünýär.')))
            else if (_orders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Häzirlikçe täze sargyt ýok.')))
            else ..._orders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(order: order, onAccept: () => _accept(order)))),
          ]),
        ),
      );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onAccept});
  final OrderSummary order;
  final VoidCallback onAccept;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(order.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), IconButton(onPressed: () => MapNavigation.openOpenStreetMap(latitude: order.deliveryLatitude, longitude: order.deliveryLongitude), icon: const Icon(Icons.navigation_outlined), tooltip: 'Kartada açmak'), Chip(label: Text('${order.price.toStringAsFixed(0)} TMT'))]),
          const SizedBox(height: 12), LocationLine(from: order.pickupAddress, to: order.deliveryAddress),
          const SizedBox(height: 12), Text('${order.weightKg} kg · #${order.number}', style: TextStyle(color: Colors.blueGrey.shade600)),
          const SizedBox(height: 14), FilledButton(onPressed: onAccept, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)), child: const Text('Kabul etmek')),
        ]),
      ));
}
