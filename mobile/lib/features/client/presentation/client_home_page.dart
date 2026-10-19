import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  int _tab = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _orders = await widget.api.myOrders(widget.session.token!); }
    catch (_) { /* Baş sahypa sargyt kartasy bolmasa-da açyk galýar. */ }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: const Padding(padding: EdgeInsets.all(8), child: AppLogo()), title: const Text('Menzil'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)), IconButton(onPressed: widget.session.logout, icon: const Icon(Icons.logout_rounded), tooltip: 'Çykmak')]),
        body: RefreshIndicator(onRefresh: _load, child: _tab == 0 ? ListView(padding: const EdgeInsets.all(20), children: [
          const AppGradientHeader(title: 'Salam!', subtitle: 'Sargydyňyzy çalt we düşnükli iberiň.', icon: Icons.local_shipping_rounded),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _newOrder, icon: const Icon(Icons.add_rounded), label: const Text('Eltip beriş sargyt et'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58))),
          const SizedBox(height: 16),
          Card(child: const Padding(padding: EdgeInsets.all(18), child: Row(children: [CircleAvatar(backgroundColor: Color(0xFFFFFBEB), child: Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B))), SizedBox(width: 12), Expanded(child: Text('Baglanyşyk kesilse, sargydyňyz saklanýar. Gaýtadan internete çykanyňyzda täzeläň.'))]))),
          const SizedBox(height: 24),
          Text('Soňky sargytlaryňyz', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
          else if (_orders.isEmpty) const _ClientEmptyState()
          else ..._orders.take(3).map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ClientOrderCard(order: order, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingPage(api: widget.api, token: widget.session.token!, orderID: order.id, order: order)))))),
          if (_orders.isNotEmpty) ...[const SizedBox(height: 8), OrderMap(orders: _orders.take(3).toList(), height: 190)],
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: () => _showHelp(context), icon: const Icon(Icons.support_agent_rounded), label: const Text('Goldaw bilen habarlaşmak')),
          const SizedBox(height: 24),
        ]) : _secondaryTab(context),),
        bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (v) => setState(() => _tab = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Baş sahypa'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Sargytlar'),
          NavigationDestination(icon: Icon(Icons.help_outline), selectedIcon: Icon(Icons.help_rounded), label: 'Kömek'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ]),
      );

  void _newOrder() => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOrderPage(session: widget.session, api: widget.api))).then((_) => _load());
  Widget _secondaryTab(BuildContext context) {
    if (_tab == 1) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Sargytlar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (_orders.isEmpty) const _ClientEmptyState(),
          ..._orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClientOrderCard(
                order: order,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LiveTrackingPage(api: widget.api, token: widget.session.token!, orderID: order.id, order: order)),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_tab == 2) return const _SimplePage(icon: Icons.support_agent_rounded, title: 'Kömek gerekmi?', text: 'Sargyt, töleg ýa-da eltiş boýunça soraglaryňyz bolsa, goldaw toparyna ýüz tutuň.');
    return _SimplePage(icon: Icons.person_outline_rounded, title: 'Profil', text: 'Telefon belgiňiz bilen ygtybarly hasap. Hasapdan çykmak üçin ýokarky düwmäni ulanyň.', action: widget.session.logout);
  }
  void _showHelp(BuildContext context) => setState(() => _tab = 2);
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({required this.icon, required this.title, required this.text, this.action});
  final IconData icon; final String title; final String text; final VoidCallback? action;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Card(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 44, color: const Color(0xFF047857)), const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center), if (action != null) ...[const SizedBox(height: 18), OutlinedButton(onPressed: action, child: const Text('Hasapdan çykmak'))]])))));
}

class _ClientEmptyState extends StatelessWidget {
  const _ClientEmptyState();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.inventory_2_outlined, size: 38, color: Color(0xFF0F766E)), const SizedBox(height: 10), const Text('Sargyt entek ýok', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text('Aşakdaky düwmä basyp ilkinji sargydyňyzy dörediň.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade600))])));
}

class _ClientOrderCard extends StatelessWidget {
  const _ClientOrderCard({required this.order, required this.onTap});
  final OrderSummary order; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, contentPadding: const EdgeInsets.all(16), leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5F1), child: Icon(Icons.local_shipping_outlined, color: Color(0xFF0F766E))), title: Text(order.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${order.pickupAddress} → ${order.deliveryAddress}', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right_rounded)));
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
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _details = TextEditingController();
  final _pickupLat = TextEditingController(text: '37.9601');
  final _pickupLng = TextEditingController(text: '58.3261');
  final _deliveryLat = TextEditingController(text: '37.9000');
  final _deliveryLng = TextEditingController(text: '58.3500');
  bool _saving = false;
  String _transport = 'car';

  @override
  void dispose() {
    for (final controller in [_title, _weight, _pickup, _delivery, _recipientName, _recipientPhone, _details, _pickupLat, _pickupLng, _deliveryLat, _deliveryLng]) { controller.dispose(); }
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final created = await widget.api.createOrder(widget.session.token!, {
        'title': _title.text, 'description': _details.text,
        'required_transport': _transport,
        'weight_kg': double.parse(_weight.text),
        'length_cm': 30.0, 'width_cm': 30.0, 'height_cm': 30.0,
        'pickup_address': _pickup.text, 'pickup_latitude': double.parse(_pickupLat.text), 'pickup_longitude': double.parse(_pickupLng.text),
        'pickup_contact_name': 'Ugradýan', 'pickup_contact_phone': '+99300000000',
        'delivery_address': _delivery.text, 'delivery_latitude': double.parse(_deliveryLat.text), 'delivery_longitude': double.parse(_deliveryLng.text),
        'delivery_contact_name': _recipientName.text, 'delivery_contact_phone': _recipientPhone.text,
        'price_amount': _estimatedPrice,
      });
      if (!mounted) return;
      final order = OrderSummary(
        id: created.id, number: 0, title: _title.text, weightKg: double.parse(_weight.text), status: 'created',
        pickupAddress: _pickup.text, pickupLatitude: double.parse(_pickupLat.text), pickupLongitude: double.parse(_pickupLng.text),
        deliveryAddress: _delivery.text, deliveryLatitude: double.parse(_deliveryLat.text), deliveryLongitude: double.parse(_deliveryLng.text), price: _estimatedPrice,
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LiveTrackingPage(api: widget.api, token: widget.session.token!, orderID: created.id, deliveryCode: created.deliveryCode, order: order)));
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLocation({required bool pickup}) async {
    final current = LatLng(
      double.parse(pickup ? _pickupLat.text : _deliveryLat.text),
      double.parse(pickup ? _pickupLng.text : _deliveryLng.text),
    );
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPickerPage(
          title: pickup ? 'Alyş nokadyny saýlaň' : 'Eltiriş nokadyny saýlaň',
          initialPoint: current,
        ),
      ),
    );
    if (point == null || !mounted) return;
    setState(() {
      final lat = point.latitude.toStringAsFixed(6);
      final lng = point.longitude.toStringAsFixed(6);
      if (pickup) {
        _pickupLat.text = lat;
        _pickupLng.text = lng;
      } else {
        _deliveryLat.text = lat;
        _deliveryLng.text = lng;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Täze sargyt')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            _section('Bukja barada', [
              TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Bukjanyň görnüşi (meselem, resminama)'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _weight, decoration: const InputDecoration(labelText: 'Soňky agram, kg'), keyboardType: TextInputType.number, validator: _number),
              const SizedBox(height: 12),
              const Text('Gerek ulag', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _TransportPicker(value: _transport, onChanged: (value) => setState(() => _transport = value)),
              const SizedBox(height: 12), TextFormField(controller: _details, maxLines: 2, decoration: const InputDecoration(labelText: 'Girelge, gat, surat ýa-da sesli düşündiriş', hintText: 'Meselem: 2-nji girelge, 4-nji gat')),
            ]),
            const SizedBox(height: 16),
            _section('Alyş nokady', [
              TextFormField(controller: _pickup, decoration: const InputDecoration(labelText: 'Salgysy'), validator: _required),
              const SizedBox(height: 8),
              _mapLocationButton(pickup: true),
            ]),
            const SizedBox(height: 16),
            _section('Eltiriş nokady', [
              TextFormField(controller: _delivery, decoration: const InputDecoration(labelText: 'Salgysy'), validator: _required),
              const SizedBox(height: 8),
              _mapLocationButton(pickup: false),
            ]),
            const SizedBox(height: 16), _section('Alyjy', [TextFormField(controller: _recipientName, decoration: const InputDecoration(labelText: 'Alyjynyň ady'), validator: _required), const SizedBox(height: 12), TextFormField(controller: _recipientPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Alyjynyň telefon belgisi'), validator: _required)]),
            const SizedBox(height: 16), Card(color: const Color(0xFFFFFBEB), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Icon(Icons.payments_outlined, color: Color(0xFFF59E0B)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Çak edilýän baha', style: TextStyle(fontWeight: FontWeight.w800)), Text('${_estimatedPrice.toStringAsFixed(0)} TMT · töleg eltişden soň tassyklanar')]))]))),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saving ? null : _create, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: Text(_saving ? 'Ugradylýar...' : 'Bahany tassyklap, sargyt et')),
          ]),
        ),
      );

  Widget _section(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 12), ...children])));
  Widget _mapLocationButton({required bool pickup}) {
    final lat = pickup ? _pickupLat.text : _deliveryLat.text;
    final lng = pickup ? _pickupLng.text : _deliveryLng.text;
    return OutlinedButton.icon(
      onPressed: () => _pickLocation(pickup: pickup),
      icon: const Icon(Icons.map_outlined),
      label: Text('Kartadan saýla • $lat, $lng'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), alignment: Alignment.centerLeft),
    );
  }
  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Bu meýdan gerek' : null;
  String? _number(String? value) => double.tryParse(value ?? '') == null ? 'San ýazylmaly' : null;
  double get _estimatedPrice { final km = const Distance().as(LengthUnit.Kilometer, LatLng(double.parse(_pickupLat.text), double.parse(_pickupLng.text)), LatLng(double.parse(_deliveryLat.text), double.parse(_deliveryLng.text))); return 20 + km * 4 + (double.tryParse(_weight.text) ?? 1) * 2; }
}

class _LocationPickerPage extends StatefulWidget {
  const _LocationPickerPage({required this.title, required this.initialPoint});
  final String title;
  final LatLng initialPoint;

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  late LatLng _selected = widget.initialPoint;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Stack(children: [
      FlutterMap(
        options: MapOptions(initialCenter: _selected, initialZoom: 14, onTap: (_, point) => setState(() => _selected = point)),
        children: [
          TileLayer(urlTemplate: 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png', tileProvider: NetworkTileProvider(attemptDecodeOfHttpErrorResponses: false), userAgentPackageName: 'com.menzil.mobile'),
          MarkerLayer(markers: [Marker(point: _selected, width: 52, height: 52, child: const Icon(Icons.location_on_rounded, color: Color(0xFF047857), size: 52))]),
        ],
      ),
      Positioned(
        left: 16, right: 16, bottom: 24,
        child: FilledButton.icon(
          onPressed: () => Navigator.pop(context, _selected),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Şu nokady saýlamak'),
        ),
      ),
    ]),
  );
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
      avatar: Icon(item.$3, size: 18, color: value == item.$1 ? Colors.white : const Color(0xFF0F766E)),
      label: Text(item.$2),
      selectedColor: const Color(0xFF0F766E),
      labelStyle: TextStyle(color: value == item.$1 ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w700),
    )],
  );
}
