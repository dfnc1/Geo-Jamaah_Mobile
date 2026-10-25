import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Abstraksi layanan lokasi (izin, status GPS, dan pengambilan posisi).
/// Memungkinkan pemalsuan (mock/fake) penuh pada unit test tanpa memanggil plugin native.
abstract class LocationService {
  /// Memeriksa apakah GPS/layanan lokasi perangkat aktif.
  Future<bool> isLocationServiceEnabled();

  /// Memeriksa status izin lokasi saat ini.
  Future<LocationPermission> checkPermission();

  /// Meminta izin lokasi ACCESS_FINE_LOCATION ke pengguna.
  Future<LocationPermission> requestPermission();

  /// Mengambil posisi koordinat GPS terkini dengan akurasi dan batas waktu tertentu.
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 20),
  });

  /// Membuka halaman pengaturan aplikasi di OS (untuk izin deniedForever).
  Future<bool> openAppSettings();

  /// Membuka halaman pengaturan lokasi/GPS di OS (saat GPS mati).
  Future<bool> openLocationSettings();
}

/// Implementasi nyata menggunakan package `geolocator`.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 20),
  }) {
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      ),
    );
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}

/// Provider global Riverpod untuk [LocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});
