import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print("Error getting available biometrics: $e");
      return [];
    }
  }

  Future<bool> authenticateWithFace() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate with Face Recognition to access the vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );
      return authenticated;
    } catch (e) {
      print("Error authenticating with face: $e");
      return false;
    }
  }

  Future<bool> authenticateWithFingerprint() async {
    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate with Fingerprint to access the vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );
      return authenticated;
    } catch (e) {
      print("Error authenticating with fingerprint: $e");
      return false;
    }
  }
}
