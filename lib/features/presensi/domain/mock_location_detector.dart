import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';

/// Abstraksi pendeteksi mock location / fake GPS.
/// Menggabungkan pengecekan dari `Position.isMocked` (geolocator)
/// ATAU `SafeDevice.isMockLocation` (safe_device).
abstract class MockLocationDetector {
  Future<bool> isMockLocation(Position position);
}

Future<bool> _defaultSafeDeviceCheck() => SafeDevice.isMockLocation;

/// Implementasi nyata pendeteksi mock location.
/// Menghitung: `position.isMocked || isMockLocationDariSafeDevice`.
/// Jika safe_device melempar error/exception, dianggap `false` dan dicatat ke Logger.
/// Nilai `true` tetap dikirimkan ke server.
class DefaultMockLocationDetector implements MockLocationDetector {
  final Future<bool> Function() _checkSafeDevice;

  const DefaultMockLocationDetector({
    Future<bool> Function() checkSafeDevice = _defaultSafeDeviceCheck,
  }) : _checkSafeDevice = checkSafeDevice;

  @override
  Future<bool> isMockLocation(Position position) async {
    final fromPosition = position.isMocked;

    bool fromSafeDevice = false;
    try {
      fromSafeDevice = await _checkSafeDevice();
    } catch (e, stack) {
      developer.log(
        'Gagal memeriksa isMockLocation dari safe_device, fallback ke false',
        name: 'MockLocationDetector',
        error: e,
        stackTrace: stack,
      );
      fromSafeDevice = false;
    }

    return fromPosition || fromSafeDevice;
  }
}

/// Provider global Riverpod untuk [MockLocationDetector].
final mockLocationDetectorProvider = Provider<MockLocationDetector>((ref) {
  return const DefaultMockLocationDetector();
});
