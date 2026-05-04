import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper quanh flutter_secure_storage.
///
/// Lưu salt PBKDF2 trên thiết bị (KHÔNG lưu master password, KHÔNG lưu key).
/// Trên Android dùng EncryptedSharedPreferences; trên Web dùng IndexedDB
/// — vì vậy bản web KHÔNG dùng class này cho dữ liệu nhạy cảm.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _saltKey = 'pbkdf2_salt';

  Future<void> writeSalt(String base64Salt) =>
      _storage.write(key: _saltKey, value: base64Salt);

  Future<String?> readSalt() => _storage.read(key: _saltKey);

  Future<void> clearAll() => _storage.deleteAll();
}
