import '../../../core/app_exception/app_exception.dart';
import '../../../core/error_mapper.dart';

/// Pemeta kode error khusus izin Musyrif; kode umum didelegasikan ke [mapAppException].
class IzinMusyrifErrorMapper {
  IzinMusyrifErrorMapper._();

  static String map(dynamic error) {
    if (error is AppException) {
      if (error.code.toUpperCase() == 'ERR_FORBIDDEN_ROLE') {
        return 'Akses ditolak: Hanya Musyrif yang dapat memverifikasi izin.';
      }
      return mapAppException(error);
    }

    return 'Terjadi kesalahan saat memproses izin. Silakan coba lagi.';
  }
}
