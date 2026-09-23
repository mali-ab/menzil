import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../shared/presentation/app_widgets.dart';
import '../../tracking/presentation/live_tracking_page.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key, required this.session, required this.api});
  final SessionController session;
  final ApiClient api;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(actions: [IconButton(onPressed: session.logout, icon: const Icon(Icons.logout_rounded), tooltip: 'Çykmak')]),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const AppGradientHeader(title: 'Salam!', subtitle: 'Sargydyňyzy birnäçe ädimde iberiň.', icon: Icons.route_rounded),
          const SizedBox(height: 24),
          Text('Näme gerek?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Card(child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.add_box_outlined, color: Color(0xFF4F46E5))),
            title: const Text('Täze sargyt döretmek', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Ýük, ugur we degişli ulag görnüşi'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateOrderPage(session: session, api: api))),
          )),
          const SizedBox(height: 16),
          Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Soňky sargytlar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 10),
              Text('Täze sargyt döredilenden soň onuň hereketini şu ýerden real wagtda yzarlap bolýar.', style: TextStyle(color: Colors.blueGrey.shade600)),
            ]),
          )),
        ]),
      );
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
      final id = await widget.api.createOrder(widget.session.token!, {
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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LiveTrackingPage(api: widget.api, token: widget.session.token!, orderID: id)));
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
              DropdownButtonFormField(value: _transport, decoration: const InputDecoration(labelText: 'Gerek ulag'), items: const [
                DropdownMenuItem(value: 'foot', child: Text('Pyýada')),
                DropdownMenuItem(value: 'bicycle', child: Text('Welosiped')),
                DropdownMenuItem(value: 'scooter', child: Text('Skuter')),
                DropdownMenuItem(value: 'car', child: Text('Awtoulag')),
                DropdownMenuItem(value: 'truck', child: Text('Ýük ulagy')),
              ], onChanged: (value) => setState(() => _transport = value!)),
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
