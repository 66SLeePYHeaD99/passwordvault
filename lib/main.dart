import 'package:flutter/material.dart';
import 'package:password_vault_app/screens/login_screen.dart';
import 'package:password_vault_app/screens/vault_screen.dart';
import 'package:password_vault_app/screens/register_screen.dart';
import 'package:password_vault_app/screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Vault',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/vault': (context) => VaultScreen(),
        '/register': (context) => RegisterScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
