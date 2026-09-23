import 'package:flutter/material.dart';

import '../../../core/session/session_controller.dart';
import '../../shared/presentation/app_widgets.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.session});
  final SessionController session;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _waiting = false;
  String _role = 'client';
  String _transport = 'car';

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _waiting = true);
    try {
      if (_register) {
        await widget.session.register(phone: _phone.text, name: _name.text, password: _password.text, role: _role, transport: _role == 'courier' ? _transport : null);
      } else {
        await widget.session.login(_phone.text, _password.text);
      }
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Icon(Icons.local_shipping_rounded, color: Color(0xFF4F46E5), size: 58),
                    const SizedBox(height: 16),
                    Text('Menzil', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Eltip beriş — ýönekeý we açyk.', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade600)),
                    const SizedBox(height: 32),
                    if (_register) ...[
                      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Doly adyňyz'), validator: _required),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon belgisi', hintText: '+993 6X XXX XXX'), validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Parol'), validator: (v) => (v?.length ?? 0) >= 8 ? null : 'Iň azyndan 8 nyşan'),
                    if (_register) ...[
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [ButtonSegment(value: 'client', label: Text('Müşderi'), icon: Icon(Icons.person_outline)), ButtonSegment(value: 'courier', label: Text('Kurýer'), icon: Icon(Icons.two_wheeler))],
                        selected: {_role},
                        onSelectionChanged: (value) => setState(() => _role = value.first),
                      ),
                      if (_role == 'courier') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _transport,
                          decoration: const InputDecoration(labelText: 'Ulag görnüşi'),
                          items: const [
                            DropdownMenuItem(value: 'foot', child: Text('Pyýada')),
                            DropdownMenuItem(value: 'bicycle', child: Text('Welosiped')),
                            DropdownMenuItem(value: 'scooter', child: Text('Skuter')),
                            DropdownMenuItem(value: 'car', child: Text('Awtoulag')),
                            DropdownMenuItem(value: 'truck', child: Text('Ýük ulagy')),
                          ],
                          onChanged: (value) => setState(() => _transport = value!),
                        ),
                      ],
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _waiting ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      child: _waiting ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_register ? 'Hasap açmak' : 'Ulgama girmek'),
                    ),
                    TextButton(onPressed: _waiting ? null : () => setState(() => _register = !_register), child: Text(_register ? 'Hasabyňyz barmy? Giriň' : 'Täze hasap açmak')),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Bu meýdan gerek' : null;
}
