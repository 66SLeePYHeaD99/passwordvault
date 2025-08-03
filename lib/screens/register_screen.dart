import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
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

  Future<void> _registerUser() async {
    final username = _usernameController.text;
    final email = _emailController.text;

    if (username.isNotEmpty && email.isNotEmpty && _canCheckBiometrics) {
      // Authenticate user biometrically during registration
      bool authenticated = await auth.authenticate(
        localizedReason: 'Register biometrics for this profile',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await secureStorage.write(key: '$username-email', value: email);
        await secureStorage.write(key: '$username-biometrics', value: 'registered');

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("User registered successfully with biometrics!"),
        ));

        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); // Return to the login screen after registration
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Biometric registration failed"),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("All fields are required and biometrics must be available!"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text("Register with Biometrics"),
            ),
          ],
        ),
      ),
    );
  }
}
