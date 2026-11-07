import '../../../core/app_exception/app_exception.dart';

/// Pemeta terpusat untuk kode error izin ke pesan bahasa Indonesia yang ramah.
/// Mencegah kode mentah (misal "ERR_XXX") tampil ke pengguna.
class IzinErrorMapper {
  IzinErrorMapper._();

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

      // 3. Error Bisnis Izin Spesifik
      switch (code) {
        case 'ERR_VALIDATION':
          return 'Data izin yang dikirim tidak valid. Periksa kembali jenis izin, tanggal, dan alasan.';
        case 'ERR_UNAUTHORIZED':
          return 'Sesi Anda telah berakhir. Silakan login kembali.';
        case 'ERR_FORBIDDEN_ROLE':
          return 'Akses ditolak: Hanya Mahasantri yang dapat mengajukan izin.';
        case 'ERR_MAHASANTRI_NOT_FOUND':
          return 'Data profil Mahasantri Anda tidak ditemukan.';
        case 'ERR_IZIN_NOT_FOUND':
          return 'Data izin tidak ditemukan.';
        case 'ERR_IZIN_ALREADY_DECIDED':
          return 'Izin sudah diputuskan dan tidak dapat diubah lagi.';
        default:
          // Jika ada pesan ramah dari server yang bukan kode mentah
          if (error.message.isNotEmpty &&
              !error.message.startsWith('ERR_') &&
              !error.message.contains('{')) {
            return error.message;
          }
          return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
      }
    }

    return 'Terjadi kesalahan saat memproses izin. Silakan coba lagi.';
  }
}
