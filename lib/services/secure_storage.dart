
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = FlutterSecureStorage();

  Future<void> addPassword(String key, String password) async {
    await _storage.write(key: key, value: password);
  }

  Future<String?> getPassword(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deletePassword(String key) async {
    await _storage.delete(key: key);
  }
}
