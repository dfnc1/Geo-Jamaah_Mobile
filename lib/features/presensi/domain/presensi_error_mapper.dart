import '../../../core/app_exception/app_exception.dart';

/// Pemeta terpusat untuk seluruh kode error presensi ke pesan bahasa Indonesia yang ramah.
/// Mencegah kode mentah (misal "ERR_XXX") tampil ke pengguna.
class PresensiErrorMapper {
  PresensiErrorMapper._();

  static String map(dynamic error) {
    if (error is AppException) {
      final code = error.code.toUpperCase();
      final status = error.status;

      // 1. Error HTTP 429 Rate Limit
      if (status == 429 || code == 'ERR_TOO_MANY_REQUESTS') {
        return 'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.';
      }

      // 2. Error Jaringan / Koneksi / Batas Waktu
      if (code == 'ERR_CONNECTION' ||
          code == 'ERR_NETWORK' ||
          code == 'ERR_TIMEOUT' ||
          code == 'ERR_CERTIFICATE') {
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      }

      // 3. Error Bisnis Presensi Spesifik
      switch (code) {
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

        case 'ERR_UNAUTHORIZED':
          return 'Sesi Anda telah berakhir. Silakan login kembali.';

        case 'ERR_FORBIDDEN_ROLE':
          return 'Akses ditolak: Hanya Mahasantri yang dapat melakukan presensi.';

        case 'ERR_MAHASANTRI_NOT_FOUND':
          return 'Data profil Mahasantri Anda tidak ditemukan.';

        default:
          return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
      }
    }

    return 'Terjadi kesalahan saat memproses presensi. Silakan coba lagi.';
  }
}
