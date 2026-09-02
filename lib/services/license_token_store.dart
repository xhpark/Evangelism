import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class LicenseTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureLicenseTokenStore implements LicenseTokenStore {
  static const String _key = 'just_ee_device_license_token';
  final FlutterSecureStorage _storage;

  SecureLicenseTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class MemoryLicenseTokenStore implements LicenseTokenStore {
  String? token;

  MemoryLicenseTokenStore({this.token});

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> delete() async {
    token = null;
  }
}
