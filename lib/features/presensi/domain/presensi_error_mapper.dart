import '../../../core/app_exception/app_exception.dart';
import '../../../core/error_mapper.dart';

/// Pemeta kode error khusus presensi; kode umum didelegasikan ke [mapAppException].
class PresensiErrorMapper {
  PresensiErrorMapper._();

  static String map(dynamic error) {
    if (error is AppException) {
      switch (error.code.toUpperCase()) {
        case 'ERR_GEOFENCE_RADIUS_EXCEEDED':
          return 'Anda berada di luar radius area masjid yang diizinkan.';
        case 'ERR_TIME_WINDOW_INVALID':
          return 'Saat ini berada di luar rentang waktu presensi untuk jadwal shalat ini.';
        case 'ERR_MOCK_LOCATION':
          return 'Terdeteksi lokasi palsu (Fake GPS). Harap nonaktifkan aplikasi lokasi tiruan lalu coba lagi.';
        case 'ERR_GPS_ACCURACY_LOW':
          return 'Akurasi GPS kurang baik (> 50 m). Pindah ke area terbuka lalu coba lagi.';
        case 'ERR_ALREADY_PRESENT':
          return 'Anda sudah presensi untuk shalat ini.';
        case 'ERR_JADWAL_NOT_FOUND':
          return 'Data jadwal shalat tidak ditemukan di server.';
        case 'ERR_MASJID_NOT_FOUND':
          return 'Data masjid tidak ditemukan di server.';
        case 'ERR_VALIDATION':
          return 'Data presensi yang dikirim tidak valid. Silakan coba lagi.';
        case 'ERR_FORBIDDEN_ROLE':
          return 'Akses ditolak: Hanya Mahasantri yang dapat melakukan presensi.';
        default:
          return mapAppException(error);
      }
    }

    return 'Terjadi kesalahan saat memproses presensi. Silakan coba lagi.';
  }
}
