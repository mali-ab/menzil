import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/session/session_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/client/presentation/client_home_page.dart';
import 'features/courier/presentation/courier_home_page.dart';

class MenzilApp extends StatelessWidget {
  const MenzilApp({super.key, required this.session, required this.api});

  final SessionController session;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => MaterialApp(
        title: 'Menzil',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: switch (session.state) {
          SessionState.loading => const _LoadingPage(),
          SessionState.unauthenticated => AuthPage(session: session),
          SessionState.authenticated when session.role == 'courier' =>
            CourierHomePage(session: session, api: api),
          SessionState.authenticated => ClientHomePage(session: session, api: api),
        },
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
