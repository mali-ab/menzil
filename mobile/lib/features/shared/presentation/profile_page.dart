import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_controller.dart';
import 'app_widgets.dart';
import 'transport_icons.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.session, required this.api, this.embedded = false});
  final SessionController session;
  final ApiClient api;
  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  ProfileData? _profile;
  String _transport = 'car';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final value = await widget.api.profile(widget.session.token!);
      if (!mounted) return;
      setState(() { _profile = value; _name.text = value.fullName; if (value.transport.isNotEmpty) _transport = value.transport; _loading = false; });
    } catch (error) { if (mounted) { setState(() => _loading = false); showError(context, error); } }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.api.updateProfile(widget.session.token!, fullName: _name.text.trim(), transport: _profile?.role == 'courier' ? _transport : null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil täzelendi')));
    } catch (error) { if (mounted) showError(context, error); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(20), children: [
      const AppGradientHeader(title: 'Profil', subtitle: 'Şahsy maglumatlaryňyzy täzeläň.', icon: Icons.manage_accounts_rounded),
      const SizedBox(height: 18),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Ady we familiýasy', prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 12),
      InputDecorator(decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone_outlined)), child: Text(_profile?.phone ?? '')),
      if (_profile?.role == 'courier') ...[
        const SizedBox(height: 18), const Text('Ulag görnüşi', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: _transport, items: ['foot','bicycle','scooter','car','truck'].map((value) => DropdownMenuItem(value: value, child: Row(children: [TransportBadge(transport: value), const SizedBox(width: 10), Text(transportLabel(value))]))).toList(), onChanged: (value) => setState(() => _transport = value!), decoration: const InputDecoration()),
      ],
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saklanýar...' : 'Saklamak')),
    ]);
    return widget.embedded ? body : Scaffold(appBar: AppBar(title: const Text('Profil')), body: body);
  }
}
