import 'package:flutter/material.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/session/session_controller.dart';
import 'core/storage/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient.fromEnvironment();
  final session = SessionController(api, TokenStorage());
  runApp(MenzilApp(session: session, api: api));
}
