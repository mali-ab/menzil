import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../shared/presentation/app_widgets.dart';
import '../../shared/presentation/profile_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, required this.session, required this.api});
  final SessionController session;
  final ApiClient api;
  @override State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  Map<String, dynamic>? _data;
  String? _error;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { _data = await widget.api.adminOverview(widget.session.token!); _error = null; } catch (e) { _error = e.toString(); } if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const Padding(padding: EdgeInsets.all(8), child: AppLogo()),
      title: const Text('Dolandyryş paneli'),
      actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(session: widget.session, api: widget.api))), icon: const Icon(Icons.manage_accounts_outlined), tooltip: 'Profil'), IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)), IconButton(onPressed: widget.session.logout, icon: const Icon(Icons.logout_rounded))],
    ),
    body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
      const AppGradientHeader(title: 'Hyzmat ýagdaýy', subtitle: 'Sargytlary we hyzmat güýjüni bir ýerde görüň.', icon: Icons.dashboard_rounded),
      const SizedBox(height: 20),
      if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(_error!)))
      else if (_data == null) const Padding(padding: EdgeInsets.all(36), child: Center(child: CircularProgressIndicator()))
      else GridView.count(crossAxisCount: 2, childAspectRatio: 1.45, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
        _Metric('Müşderiler', _data!['clients'], Icons.people_outline), _Metric('Kurýerler', _data!['couriers'], Icons.two_wheeler_outlined),
        _Metric('Soňkyra taýýar', _data!['available_couriers'], Icons.gps_fixed), _Metric('Aktiw sargytlar', _data!['open_orders'], Icons.route_outlined),
        _Metric('Soňky eltişler', _data!['delivered_today'], Icons.check_circle_outline), _Metric('Şikaýatlar', _data!['complaints'], Icons.support_agent_outlined),
      ]),
      const SizedBox(height: 20),
      const Text('Sebitler, tölegler we şikaýatlar üçin API modeliniň giňeldilmegi indiki tapgyrda şu panelden dolandyrylar.'),
    ])),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label; final dynamic value; final IconData icon;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFF047857)), const Spacer(), Text('${value ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 12))])));
}
