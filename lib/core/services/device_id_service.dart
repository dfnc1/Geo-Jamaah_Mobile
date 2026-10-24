import 'package:android_id/android_id.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider untuk layanan pembacaan Device ID perangkat.
final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return const AndroidDeviceIdService();
});

/// Interface abstraksi Device ID agar mudah diuji secara unit test.
abstract class DeviceIdService {
  Future<String?> getDeviceId();
}

/// Implementasi pembacaan Device ID Android berbasis AndroidId plugin.
class AndroidDeviceIdService implements DeviceIdService {
  final AndroidId _androidId;

  const AndroidDeviceIdService([this._androidId = const AndroidId()]);

  @override
  Future<String?> getDeviceId() async {
    try {
      final id = await _androidId.getId();
      if (id == null || id.trim().isEmpty) return null;
      return id.trim();
    } catch (_) {
      return null;
    }
  }
}
