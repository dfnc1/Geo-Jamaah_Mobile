import '../../../core/app_exception/app_exception.dart';

class AdminErrorMapper {
  AdminErrorMapper._();

  static String map(Object error) {
    if (error is AppException) {
      switch (error.code) {
        case 'ERR_MAHASANTRI_NOT_FOUND':
          return 'Mahasantri dengan NIM tersebut tidak ditemukan.';
        case 'ERR_JADWAL_NOT_FOUND':
          return 'Jadwal sholat tidak ditemukan.';
        case 'ERR_TIME_WINDOW_INVALID':
          return 'Waktu akhir presensi jadwal ini belum lewat.';
        case 'ERR_MASJID_NOT_FOUND':
          return 'Data masjid tidak ditemukan untuk masjid utama.';
        case 'ERR_FORBIDDEN_ROLE':
          return 'Akses ditolak: Anda tidak memiliki hak akses Admin.';
        case 'ERR_VALIDATION':
          return 'Data atau parameter yang dimasukkan tidak valid.';
        case 'ERR_NETWORK':
        case 'ERR_CONNECTION':
          return 'Gagal terhubung ke server. Periksa koneksi Anda.';
        case 'ERR_TIMEOUT':
          return 'Waktu permintaan habis. Silakan coba lagi.';
        default:
          return error.message;
      }
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
