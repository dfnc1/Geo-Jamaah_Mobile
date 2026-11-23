import '../../../core/app_exception/app_exception.dart';
import '../../../core/error_mapper.dart';

/// Pemeta kode error khusus izin Mahasantri; kode umum didelegasikan ke [mapAppException].
class IzinErrorMapper {
  IzinErrorMapper._();

  static String map(dynamic error) {
    if (error is AppException) {
      switch (error.code.toUpperCase()) {
        case 'ERR_VALIDATION':
          return 'Data izin yang dikirim tidak valid. Periksa kembali jenis izin, tanggal, dan alasan.';
        case 'ERR_FORBIDDEN_ROLE':
          return 'Akses ditolak: Hanya Mahasantri yang dapat mengajukan izin.';
        case 'ERR_IZIN_NOT_FOUND':
          return 'Data izin tidak ditemukan.';
        default:
          return mapAppException(error);
      }
    }

    return 'Terjadi kesalahan saat memproses izin. Silakan coba lagi.';
  }
}
