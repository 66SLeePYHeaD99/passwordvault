import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:password_vault_app/screens/register_screen.dart'; // Import RegisterScreen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();

  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = await auth.canCheckBiometrics;
    List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

    setState(() {
      _canCheckBiometrics = canCheck;
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _loginUser() async {
    final username = _usernameController.text;

    if (username.isNotEmpty) {
      final email = await secureStorage.read(key: '$username-email');
      final biometricsRegistered = await secureStorage.read(key: '$username-biometrics');

      if (email != null && biometricsRegistered == 'registered') {
        // Authenticate user biometrically
        bool authenticated = await auth.authenticate(
          localizedReason: 'Log in with your biometrics',
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );

        if (authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Login successful for $username!"),
          ));

          Navigator.of(context).pushReplacementNamed('/vault');  // Navigate to the main screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Biometric authentication failed"),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("No such user registered with biometrics"),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Username is required"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login with Biometrics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginUser,
              child: Text("Login with Biometrics"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text("Don't have an account? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}
