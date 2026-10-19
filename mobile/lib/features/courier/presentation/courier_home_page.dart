import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../shared/presentation/app_widgets.dart';
import '../../shared/presentation/order_map.dart';
import '../../shared/presentation/profile_page.dart';
import '../../shared/presentation/transport_icons.dart';
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
  List<OrderSummary> _availableOrders = [];
  List<OrderSummary> _activeOrders = [];
  List<OrderSummary> _history = [];
  bool _available = false;
  bool _loading = true;
  String? _error;
  int _tab = 0;

  @override
  void initState() { super.initState(); _tracking = LocationTrackingService(widget.api); _load(); }
  @override
  void dispose() { _tracking.stop(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Future.wait([widget.api.availableOrders(widget.session.token!), widget.api.activeOrders(widget.session.token!), widget.api.myOrders(widget.session.token!)]);
      _availableOrders = result[0];
      _activeOrders = result[1];
      _history = result[2];
    } catch (error) { _error = error.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _availability(bool value) async {
    try {
      await widget.api.setAvailability(widget.session.token!, value);
      if (mounted) setState(() => _available = value);
      if (!value) { await _tracking.stop(); return; }
      await _load();
      try { await _tracking.start(widget.session.token!); }
      catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soňkyra çykdyňyz, emma geolokasiýa işlemeýär. GPS rugsadyny barlaň.'))); }
    } catch (error) { if (mounted) showError(context, error); }
  }

  Future<void> _accept(OrderSummary order) async {
    try {
      await widget.api.acceptOrder(widget.session.token!, order.id);
      await _load();
      if (mounted) {
        setState(() => _tab = 1);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sargyt kabul edildi. Ol indi Aktiw sargytlarda.')));
      }
    } catch (error) { if (mounted) showError(context, error); }
  }

  Future<void> _advance(OrderSummary order) async {
    if (order.status == 'delivering') {
      await _showProofSheet(order);
      return;
    }
    final next = switch (order.status) { 'accepted' => 'to_pickup', 'to_pickup' => 'delivering', _ => 'delivered' };
    try { await widget.api.changeStatus(widget.session.token!, order.id, next); await _load(); }
    catch (error) { if (mounted) showError(context, error); }
  }

  Future<void> _showProofSheet(OrderSummary order) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _DeliveryProofSheet(api: widget.api, token: widget.session.token!, order: order));
    await _load();
  }

  Future<void> _showOrderMap(OrderSummary order) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          OrderMap(orders: [order], height: MediaQuery.sizeOf(sheetContext).height * .58, navigationMode: true),
          const SizedBox(height: 12),
          LocationLine(from: order.pickupAddress, to: order.deliveryAddress),
        ]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const Padding(padding: EdgeInsets.all(8), child: AppLogo()), title: const Text('Kurýer merkezi'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(session: widget.session, api: widget.api))), icon: const Icon(Icons.manage_accounts_outlined), tooltip: 'Profil'), IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)), IconButton(onPressed: widget.session.logout, icon: const Icon(Icons.logout_rounded))]),
    body: RefreshIndicator(onRefresh: _load, child: _tab == 0 ? _jobsTab(context) : _tab == 1 ? _activeTab(context) : _earningsTab(context)),
    bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (index) => setState(() => _tab = index), destinations: [
      const NavigationDestination(icon: Icon(Icons.view_list_outlined), selectedIcon: Icon(Icons.view_list_rounded), label: 'Sargytlar'),
      NavigationDestination(icon: Badge(isLabelVisible: _activeOrders.isNotEmpty, child: const Icon(Icons.route_outlined)), selectedIcon: const Icon(Icons.route_rounded), label: 'Aktiwler'),
      const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Gazanç'),
    ]),
  );

  Widget _jobsTab(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    AppGradientHeader(title: _available ? 'Işde' : 'Dynçda', subtitle: _available ? 'Ýakyndaky täze sargytlar size açyk.' : 'Sargyt kabul etmek üçin «Işde» ýagdaýyny açyň.', icon: _available ? Icons.gps_fixed : Icons.pause_circle_outline),
    const SizedBox(height: 16),
    Card(child: SwitchListTile.adaptive(value: _available, onChanged: _availability, secondary: Icon(_available ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: _available ? const Color(0xFF047857) : Colors.grey), title: Text(_available ? 'Işde' : 'Dynçda', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(_available ? 'GPS ${_tracking.isRunning ? 'işleýär' : 'garaşýar'}' : 'Soňkyra çykmak üçin açyň'))),
    const SizedBox(height: 24), Text('Size laýyk sargytlar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
    if (_loading) const _LoadingCard()
    else if (_error != null) _ErrorCard(message: _error!, onRetry: _load)
    else if (!_available) const _InfoCard(icon: Icons.toggle_off_outlined, text: 'Soňkyra çykanyňyzda ulag görnüşiňize laýyk sargytlar görünýär.')
    else if (_availableOrders.isEmpty) const _InfoCard(icon: Icons.inbox_outlined, text: 'Häzirlikçe täze sargyt ýok.')
    else ...[
      OrderMap(orders: _availableOrders, height: 250),
      const SizedBox(height: 16),
      ..._availableOrders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(order: order, actionLabel: 'Kabul etmek', action: () => _accept(order), onMapTap: () => _showOrderMap(order)))),
    ],
  ]);

  Widget _activeTab(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Text('Aktiw sargytlar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6),
    Text('Kabul eden sargytlaryňyz we olaryň ugurlary.', style: TextStyle(color: Colors.blueGrey.shade600)), const SizedBox(height: 18),
    if (_loading) const _LoadingCard()
    else if (_error != null) _ErrorCard(message: _error!, onRetry: _load)
    else if (_activeOrders.isEmpty) const _InfoCard(icon: Icons.route_outlined, text: 'Soňky kabul edilen sargytlar şu ýerde görüner.')
    else ...[OrderMap(orders: _activeOrders, height: 420, navigationMode: true), const SizedBox(height: 20), ..._activeOrders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(order: order, actionLabel: _nextAction(order.status), action: () => _advance(order), showStatus: true, onMapTap: () => _showOrderMap(order))))],
  ]);

  Widget _earningsTab(BuildContext context) {
    final completed = _history.where((order) => order.status == 'delivered').toList();
    final total = completed.fold<double>(0, (sum, order) => sum + order.price);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Gazanç', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      Card(color: const Color(0xFF047857), child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Tamamlanan sargytlar boýunça', style: TextStyle(color: Color(0xFFD1FAE5))), const SizedBox(height: 8), Text('${total.toStringAsFixed(0)} TMT', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)), Text('${completed.length} sargyt', style: const TextStyle(color: Color(0xFFD1FAE5)))]))),
      const SizedBox(height: 20), const Text('Soňky iş taryhy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
      if (_loading) const _LoadingCard() else if (completed.isEmpty) const _InfoCard(icon: Icons.receipt_long_outlined, text: 'Tamamlanan sargytlaryňyz şu ýerde görüner.') else ...completed.map((order) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: ListTile(leading: const Icon(Icons.check_circle_outline, color: Color(0xFF047857)), title: Text(order.title), subtitle: Text('#${order.number} · Gowşuryldy'), trailing: Text('${order.price.toStringAsFixed(0)} TMT', style: const TextStyle(fontWeight: FontWeight.w800)))))),
    ]);
  }

  String _nextAction(String status) => switch (status) { 'accepted' => 'Alyş nokadyna barýaryn', 'to_pickup' => 'Ýüki aldym', _ => 'Eltirildi' };
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.actionLabel, required this.action, this.showStatus = false, this.onMapTap});
  final OrderSummary order; final String actionLabel; final VoidCallback action; final bool showStatus; final VoidCallback? onMapTap;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(order.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Chip(avatar: const Icon(Icons.payments_outlined, size: 16), label: Text('${order.price.toStringAsFixed(0)} TMT'))]),
    if (showStatus) Padding(padding: const EdgeInsets.only(bottom: 12), child: _StatusPill(status: order.status)),
    LocationLine(from: order.pickupAddress, to: order.deliveryAddress), const SizedBox(height: 12),
    Row(children: [TransportBadge(transport: order.transport), const SizedBox(width: 8), Text('${transportLabel(order.transport)} · ${order.weightKg} kg · #${order.number}', style: TextStyle(color: Colors.blueGrey.shade600))]), const SizedBox(height: 14),
    if (onMapTap != null) ...[OutlinedButton.icon(onPressed: onMapTap, icon: const Icon(Icons.map_outlined), label: const Text('Kartada görmek'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))), const SizedBox(height: 8)],
    FilledButton.icon(onPressed: action, icon: Icon(showStatus ? Icons.arrow_forward_rounded : Icons.check_circle_outline), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)), label: Text(actionLabel)),
  ])));
}

class _StatusPill extends StatelessWidget { const _StatusPill({required this.status}); final String status; @override Widget build(BuildContext context) { final label = {'accepted': 'Kabul edildi', 'to_pickup': 'Alyş nokadyna barýar', 'delivering': 'Eltip barýar'}[status] ?? status; return Chip(avatar: const Icon(Icons.timelapse_rounded, size: 16), label: Text(label)); } }
class _LoadingCard extends StatelessWidget { const _LoadingCard(); @override Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator())); }
class _InfoCard extends StatelessWidget { const _InfoCard({required this.icon, required this.text}); final IconData icon; final String text; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [Icon(icon, color: const Color(0xFF0F766E), size: 34), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center)]))); }
class _ErrorCard extends StatelessWidget { const _ErrorCard({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Text(message, textAlign: TextAlign.center), TextButton(onPressed: onRetry, child: const Text('Gaýtadan syna'))]))); }

class _DeliveryProofSheet extends StatefulWidget {
  const _DeliveryProofSheet({required this.api, required this.token, required this.order});
  final ApiClient api; final String token; final OrderSummary order;
  @override State<_DeliveryProofSheet> createState() => _DeliveryProofSheetState();
}

class _DeliveryProofSheetState extends State<_DeliveryProofSheet> {
  final _code = TextEditingController();
  XFile? _photo;
  String? _error;
  bool _sending = false;
  @override void dispose() { _code.dispose(); super.dispose(); }
  Future<void> _otp() async { setState(() { _sending = true; _error = null; }); try { await widget.api.verifyDeliveryOTP(widget.token, widget.order.id, _code.text.trim()); if (mounted) Navigator.pop(context); } catch (_) { if (mounted) setState(() => _error = 'OTP kody nädogry ýa-da möhleti gutardy.'); } finally { if (mounted) setState(() => _sending = false); } }
  Future<void> _pick() async { final photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1600); if (photo != null && mounted) setState(() { _photo = photo; _error = null; }); }
  Future<void> _upload() async { if (_photo == null) { setState(() => _error = 'Ilki foto düşüriň.'); return; } setState(() { _sending = true; _error = null; }); try { await widget.api.submitDeliveryPhoto(widget.token, widget.order.id, _photo!.path); if (mounted) Navigator.pop(context); } catch (error) { if (mounted) setState(() => _error = error.toString()); } finally { if (mounted) setState(() => _sending = false); } }
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20,20,20,20 + MediaQuery.viewInsetsOf(context).bottom), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('Eltirişi tassykla', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('Alyjydan OTP koduny soraň ýa-da eltişi foto bilen tassyklaň.'), const SizedBox(height: 18),
    TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: '6 belgili OTP kod')), FilledButton(onPressed: _sending ? null : _otp, child: const Text('OTP bilen tassyklamak')),
    const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('ýa-da')), Expanded(child: Divider())])),
    OutlinedButton.icon(onPressed: _sending ? null : _pick, icon: const Icon(Icons.camera_alt_outlined), label: Text(_photo == null ? 'Foto düşürmek' : 'Foto saýlandy: ${_photo!.name}')),
    FilledButton.tonalIcon(onPressed: _sending ? null : _upload, icon: const Icon(Icons.upload_rounded), label: const Text('Foto bilen tassyklamak')),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
  ]))));
}
