import 'app_exception/app_exception.dart';

/// Pemeta kode error server ke pesan pengguna dalam bahasa Indonesia.
/// Tidak pernah menampilkan pesan mentah dari server.
String mapAppException(dynamic error) {
  if (error is AppException) {
    final code = error.code.toUpperCase();
    final status = error.status;

    if (status == 429 || code == 'ERR_TOO_MANY_REQUESTS') {
      return 'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.';
    }

    if (code == 'ERR_CONNECTION' ||
        code == 'ERR_NETWORK' ||
        code == 'ERR_TIMEOUT' ||
        code == 'ERR_CERTIFICATE') {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    switch (code) {
      case 'ERR_VALIDATION':
        return 'Data tidak valid. Silakan coba lagi.';
      case 'ERR_UNAUTHORIZED':
        return 'Sesi Anda telah berakhir. Silakan login kembali.';
      case 'ERR_FORBIDDEN_ROLE':
        return 'Akses ditolak.';
      case 'ERR_NOT_YOUR_STUDENT':
        return 'Ini bukan santri binaan Anda.';
      case 'ERR_IZIN_NOT_FOUND':
        return 'Izin tidak ditemukan.';
      case 'ERR_IZIN_ALREADY_DECIDED':
        return 'Izin sudah diputuskan dan tidak dapat diubah lagi.';
      case 'ERR_MAHASANTRI_NOT_FOUND':
        return 'Data profil Mahasantri Anda tidak ditemukan.';
      case 'ERR_MUSYRIF_NOT_FOUND':
        return 'Profil Musyrif tidak ditemukan.';
      case 'ERR_JADWAL_NOT_FOUND':
        return 'Data jadwal shalat tidak ditemukan.';
      case 'ERR_MASJID_NOT_FOUND':
        return 'Data masjid tidak ditemukan.';
      default:
        return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
    }
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}
