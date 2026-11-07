import '../../../core/app_exception/app_exception.dart';

/// Pemeta kode error endpoint Musyrif ke pesan bahasa Indonesia yang ramah.
/// Digunakan oleh Izin, DSS/Kritis, Monitoring, dan Tren Kehadiran.
class MusyrifErrorMapper {
  MusyrifErrorMapper._();

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

      // 3. Error Bisnis Musyrif Spesifik
      switch (code) {
        case 'ERR_VALIDATION':
          return 'Data tidak valid. Silakan coba lagi.';
        case 'ERR_UNAUTHORIZED':
          return 'Sesi Anda telah berakhir. Silakan login kembali.';
        case 'ERR_FORBIDDEN_ROLE':
          return 'Akses ditolak: Hanya Musyrif yang dapat mengakses fitur ini.';
        case 'ERR_MUSYRIF_NOT_FOUND':
          return 'Profil Musyrif tidak ditemukan.';
        case 'ERR_NOT_YOUR_STUDENT':
          return 'Ini bukan santri binaan Anda.';
        case 'ERR_IZIN_NOT_FOUND':
          return 'Izin tidak ditemukan.';
        case 'ERR_IZIN_ALREADY_DECIDED':
          return 'Izin sudah diputuskan dan tidak dapat diubah lagi.';
        case 'ERR_JADWAL_NOT_FOUND':
          return 'Data jadwal shalat tidak ditemukan.';
        case 'ERR_MASJID_NOT_FOUND':
          return 'Data masjid tidak ditemukan.';
        default:
          if (error.message.isNotEmpty &&
              !error.message.startsWith('ERR_') &&
              !error.message.contains('{')) {
            return error.message;
          }
          return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
      }
    }

    return 'Terjadi kesalahan saat memproses data. Silakan coba lagi.';
  }
}
