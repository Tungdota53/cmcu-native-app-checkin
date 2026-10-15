import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models.dart';

/// Lưu [Session] trong Keychain (iOS) / EncryptedSharedPreferences (Android).
class SessionStore {
  SessionStore._();
  static const _key = 'session';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static Future<Session?> load() async => Session.decode(await _storage.read(key: _key));
  static Future<void> save(Session s) => _storage.write(key: _key, value: s.encode());
  static Future<void> clear() => _storage.delete(key: _key);
}
