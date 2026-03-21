import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure credential storage using platform keychain/Keystore
/// Use for: refresh tokens, API keys, sensitive user data
class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance =>
      _instance ??= SecureStorageService._();

  SecureStorageService._();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  );

  static const _iOsOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  FlutterSecureStorage? _storage;

  FlutterSecureStorage get _safeStorage {
    _storage ??= const FlutterSecureStorage(
      aOptions: _androidOptions,
      iOptions: _iOsOptions,
    );
    return _storage!;
  }

  /// Store a value securely
  Future<void> write(String key, String value) async {
    try {
      if (kIsWeb) return; // flutter_secure_storage has limited web support
      await _safeStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('SecureStorage write error: $e');
    }
  }

  /// Read a value
  Future<String?> read(String key) async {
    try {
      if (kIsWeb) return null;
      return await _safeStorage.read(key: key);
    } catch (e) {
      debugPrint('SecureStorage read error: $e');
      return null;
    }
  }

  /// Delete a value
  Future<void> delete(String key) async {
    try {
      if (kIsWeb) return;
      await _safeStorage.delete(key: key);
    } catch (e) {
      debugPrint('SecureStorage delete error: $e');
    }
  }

  /// Delete all values
  Future<void> deleteAll() async {
    try {
      if (kIsWeb) return;
      await _safeStorage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorage deleteAll error: $e');
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    return (await read(key)) != null;
  }

  // Standard keys for credentials
  static const String keyRefreshToken = 'vottery_refresh_token';
  static const String keySupabaseSession = 'vottery_supabase_session';
  static const String keyBiometricEnabled = 'vottery_biometric_enabled';
  static const String keyPinnedCertHash = 'vottery_ssl_pinned_hash';
}
