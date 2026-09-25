import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../shared/presentation/app_widgets.dart';
import '../../shared/presentation/order_map.dart';
import '../../tracking/presentation/live_tracking_page.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key, required this.session, required this.api});
  final SessionController session;
  final ApiClient api;

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  List<OrderSummary> _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _orders = await widget.api.myOrders(widget.session.token!); }
    catch (_) { /* Baş sahypa sargyt kartasy bolmasa-da açyk galýar. */ }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)), IconButton(onPressed: widget.session.logout, icon: const Icon(Icons.logout_rounded), tooltip: 'Çykmak')]),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOrderPage(session: widget.session, api: widget.api))).then((_) => _load()), icon: const Icon(Icons.add_rounded), label: const Text('Täze sargyt')),
        body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
          const AppGradientHeader(title: 'Salam!', subtitle: 'Sargydyňyzy birnäçe ädimde iberiň.', icon: Icons.route_rounded),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const CircleAvatar(backgroundColor: Color(0xFFECFDF5), child: Icon(Icons.stars_rounded, color: Color(0xFF059669))), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('120 bonus bal', style: TextStyle(fontWeight: FontWeight.w800)), Text('Soňky sargytlaryňyz üçin ýygnaldy')])), TextButton(onPressed: () {}, child: const Text('Ulanyş'))]))),
          const SizedBox(height: 24),
          Text('Soňky sargytlaryňyz', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else if (_orders.isEmpty) const _ClientEmptyState()
          else ..._orders.take(3).map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ClientOrderCard(order: order, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingPage(api: widget.api, token: widget.session.token!, orderID: order.id)))))),
          if (_orders.isNotEmpty) ...[const SizedBox(height: 8), OrderMap(orders: _orders.take(3).toList(), height: 190)],
          const SizedBox(height: 92),
        ])),
      );
}

class _ClientEmptyState extends StatelessWidget {
  const _ClientEmptyState();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.inventory_2_outlined, size: 38, color: Color(0xFF4F46E5)), const SizedBox(height: 10), const Text('Sargyt entek ýok', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text('Aşakdaky düwmä basyp ilkinji sargydyňyzy dörediň.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade600))])));
}

class _ClientOrderCard extends StatelessWidget {
  const _ClientOrderCard({required this.order, required this.onTap});
  final OrderSummary order; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.all(16), leading: const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.local_shipping_outlined, color: Color(0xFF4F46E5))), title: Text(order.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${order.pickupAddress} → ${order.deliveryAddress}', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right_rounded)));
}

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key, required this.session, required this.api});
  final SessionController session;
  final ApiClient api;
  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Ýük');
  final _weight = TextEditingController(text: '1');
  final _pickup = TextEditingController();
  final _delivery = TextEditingController();
  final _pickupLat = TextEditingController(text: '37.9601');
  final _pickupLng = TextEditingController(text: '58.3261');
  final _deliveryLat = TextEditingController(text: '37.9000');
  final _deliveryLng = TextEditingController(text: '58.3500');
  bool _saving = false;
  String _transport = 'car';

  @override
  void dispose() {
    for (final controller in [_title, _weight, _pickup, _delivery, _pickupLat, _pickupLng, _deliveryLat, _deliveryLng]) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final created = await widget.api.createOrder(widget.session.token!, {
        'title': _title.text,
        'required_transport': _transport,
        'weight_kg': double.parse(_weight.text),
        'length_cm': 30.0, 'width_cm': 30.0, 'height_cm': 30.0,
        'pickup_address': _pickup.text, 'pickup_latitude': double.parse(_pickupLat.text), 'pickup_longitude': double.parse(_pickupLng.text),
        'pickup_contact_name': 'Ugradýan', 'pickup_contact_phone': '+99300000000',
        'delivery_address': _delivery.text, 'delivery_latitude': double.parse(_deliveryLat.text), 'delivery_longitude': double.parse(_deliveryLng.text),
        'delivery_contact_name': 'Alyjy', 'delivery_contact_phone': '+99300000000',
        'price_amount': 30.0,
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LiveTrackingPage(api: widget.api, token: widget.session.token!, orderID: created.id, deliveryCode: created.deliveryCode)));
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Täze sargyt')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            _section('Ýük', [
              TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Ýüküň ady'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _weight, decoration: const InputDecoration(labelText: 'Soňky agram, kg'), keyboardType: TextInputType.number, validator: _number),
              const SizedBox(height: 12),
              const Text('Gerek ulag', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _TransportPicker(value: _transport, onChanged: (value) => setState(() => _transport = value)),
            ]),
            const SizedBox(height: 16),
            _section('Alyş nokady', [
              TextFormField(controller: _pickup, decoration: const InputDecoration(labelText: 'Salgysy'), validator: _required),
              const SizedBox(height: 8),
              _coordinates(_pickupLat, _pickupLng),
            ]),
            const SizedBox(height: 16),
            _section('Eltiriş nokady', [
              TextFormField(controller: _delivery, decoration: const InputDecoration(labelText: 'Salgysy'), validator: _required),
              const SizedBox(height: 8),
              _coordinates(_deliveryLat, _deliveryLng),
            ]),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _create, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: Text(_saving ? 'Ugradylýar...' : 'Sargydy ugratmak')),
          ]),
        ),
      );

  Widget _section(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 12), ...children])));
  Widget _coordinates(TextEditingController lat, TextEditingController lng) => Row(children: [Expanded(child: TextFormField(controller: lat, decoration: const InputDecoration(labelText: 'Giňlik'), keyboardType: TextInputType.number, validator: _number)), const SizedBox(width: 8), Expanded(child: TextFormField(controller: lng, decoration: const InputDecoration(labelText: 'Uzynlyk'), keyboardType: TextInputType.number, validator: _number))]);
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Bu meýdan gerek' : null;
  String? _number(String? value) => double.tryParse(value ?? '') == null ? 'San ýazylmaly' : null;
}

class _TransportPicker extends StatelessWidget {
  const _TransportPicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  static const _items = [
    ('foot', 'Pyýada', Icons.directions_walk_rounded),
    ('bicycle', 'Welosiped', Icons.pedal_bike_rounded),
    ('scooter', 'Skuter', Icons.electric_scooter_rounded),
    ('car', 'Awtoulag', Icons.directions_car_rounded),
    ('truck', 'Ýük ulagy', Icons.local_shipping_rounded),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [for (final item in _items) ChoiceChip(
      selected: value == item.$1,
      onSelected: (_) => onChanged(item.$1),
      avatar: Icon(item.$3, size: 18, color: value == item.$1 ? Colors.white : const Color(0xFF4F46E5)),
      label: Text(item.$2),
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(color: value == item.$1 ? Colors.white : const Color(0xFF16213E), fontWeight: FontWeight.w700),
    )],
  );
}
