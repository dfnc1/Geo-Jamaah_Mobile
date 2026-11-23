import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider global untuk TokenStore.
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

/// Penyimpanan token autentikasi dan data pengguna (JSON)
/// secara aman menggunakan FlutterSecureStorage.
class TokenStore {
  final FlutterSecureStorage _storage;

  static const String _keyToken = 'geo_jamaah_access_token';
  static const String _keyUser = 'geo_jamaah_user_data';

  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Simpan JWT access token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Ambil JWT access token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } on PlatformException {
      // Keystore rusak/tidak cocok pasca restore OS: bersihkan agar login tidak terkunci.
      await _clearSilently();
      return null;
    }
  }

  /// Hapus JWT access token
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  /// Simpan data user (Map/JSON)
  Future<void> saveUser(Map<String, dynamic> userJson) async {
    await _storage.write(key: _keyUser, value: jsonEncode(userJson));
  }

  /// Ambil data user dalam bentuk Map
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final raw = await _storage.read(key: _keyUser);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } on PlatformException {
      await _clearSilently();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearSilently() async {
    try {
      await clear();
    } catch (_) {}
  }

  /// Hapus data user
  Future<void> deleteUser() async {
    await _storage.delete(key: _keyUser);
  }

  /// Bersihkan seluruh data sesi autentikasi
  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
