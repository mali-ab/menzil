import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../shared/presentation/app_widgets.dart';
import '../../shared/presentation/order_map.dart';
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
      final result = await Future.wait([widget.api.availableOrders(widget.session.token!), widget.api.activeOrders(widget.session.token!)]);
      _availableOrders = result[0];
      _activeOrders = result[1];
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
    final next = switch (order.status) { 'accepted' => 'to_pickup', 'to_pickup' => 'delivering', _ => 'delivered' };
    try { await widget.api.changeStatus(widget.session.token!, order.id, next); await _load(); }
    catch (error) { if (mounted) showError(context, error); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kurýer merkezi'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)), IconButton(onPressed: widget.session.logout, icon: const Icon(Icons.logout_rounded))]),
    body: RefreshIndicator(onRefresh: _load, child: _tab == 0 ? _jobsTab(context) : _activeTab(context)),
    bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (index) => setState(() => _tab = index), destinations: [
      const NavigationDestination(icon: Icon(Icons.view_list_outlined), selectedIcon: Icon(Icons.view_list_rounded), label: 'Sargytlar'),
      NavigationDestination(icon: Badge(isLabelVisible: _activeOrders.isNotEmpty, child: const Icon(Icons.route_outlined)), selectedIcon: const Icon(Icons.route_rounded), label: 'Aktiwler'),
    ]),
  );

  Widget _jobsTab(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    AppGradientHeader(title: _available ? 'Siz setirde' : 'Soňkyra setire çykyň', subtitle: _available ? 'Täze sargytlar size açyk.' : 'Sargyt kabul etmek üçin elýeterli boluň.', icon: _available ? Icons.gps_fixed : Icons.pause_circle_outline),
    const SizedBox(height: 16),
    Card(child: SwitchListTile.adaptive(value: _available, onChanged: _availability, secondary: Icon(_available ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: _available ? Colors.green : Colors.grey), title: const Text('Elýeterli', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(_available ? 'Soňkyra çykdyňyz · GPS ${_tracking.isRunning ? 'işleýär' : 'garaşýar'}' : 'Soňkyra çykmak üçin açyň'))),
    const SizedBox(height: 24), Text('Size laýyk sargytlar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
    if (_loading) const _LoadingCard()
    else if (_error != null) _ErrorCard(message: _error!, onRetry: _load)
    else if (!_available) const _InfoCard(icon: Icons.toggle_off_outlined, text: 'Soňkyra çykanyňyzda ulag görnüşiňize laýyk sargytlar görünýär.')
    else if (_availableOrders.isEmpty) const _InfoCard(icon: Icons.inbox_outlined, text: 'Häzirlikçe täze sargyt ýok.')
    else ..._availableOrders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(order: order, actionLabel: 'Kabul etmek', action: () => _accept(order)))),
  ]);

  Widget _activeTab(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Text('Aktiw sargytlar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6),
    Text('Kabul eden sargytlaryňyz we olaryň ugurlary.', style: TextStyle(color: Colors.blueGrey.shade600)), const SizedBox(height: 18),
    if (_loading) const _LoadingCard()
    else if (_error != null) _ErrorCard(message: _error!, onRetry: _load)
    else if (_activeOrders.isEmpty) const _InfoCard(icon: Icons.route_outlined, text: 'Soňky kabul edilen sargytlar şu ýerde görüner.')
    else ...[OrderMap(orders: _activeOrders, height: 290), const SizedBox(height: 20), ..._activeOrders.map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(order: order, actionLabel: _nextAction(order.status), action: () => _advance(order), showStatus: true)))],
  ]);

  String _nextAction(String status) => switch (status) { 'accepted' => 'Alyş nokadyna barýaryn', 'to_pickup' => 'Ýüki aldym', _ => 'Eltirildi' };
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.actionLabel, required this.action, this.showStatus = false});
  final OrderSummary order; final String actionLabel; final VoidCallback action; final bool showStatus;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(order.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Chip(label: Text('${order.price.toStringAsFixed(0)} TMT'))]),
    if (showStatus) Padding(padding: const EdgeInsets.only(bottom: 12), child: _StatusPill(status: order.status)),
    LocationLine(from: order.pickupAddress, to: order.deliveryAddress), const SizedBox(height: 12),
    Text('${order.weightKg} kg · #${order.number}', style: TextStyle(color: Colors.blueGrey.shade600)), const SizedBox(height: 14),
    FilledButton.icon(onPressed: action, icon: Icon(showStatus ? Icons.arrow_forward_rounded : Icons.check_circle_outline), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)), label: Text(actionLabel)),
  ])));
}

class _StatusPill extends StatelessWidget { const _StatusPill({required this.status}); final String status; @override Widget build(BuildContext context) { final label = {'accepted': 'Kabul edildi', 'to_pickup': 'Alyş nokadyna barýar', 'delivering': 'Eltip barýar'}[status] ?? status; return Chip(avatar: const Icon(Icons.timelapse_rounded, size: 16), label: Text(label)); } }
class _LoadingCard extends StatelessWidget { const _LoadingCard(); @override Widget build(BuildContext context) => const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator())); }
class _InfoCard extends StatelessWidget { const _InfoCard({required this.icon, required this.text}); final IconData icon; final String text; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [Icon(icon, color: const Color(0xFF4F46E5), size: 34), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center)]))); }
class _ErrorCard extends StatelessWidget { const _ErrorCard({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Text(message, textAlign: TextAlign.center), TextButton(onPressed: onRetry, child: const Text('Gaýtadan syna'))]))); }
