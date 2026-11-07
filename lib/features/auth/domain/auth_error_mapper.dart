import '../../../core/app_exception/app_exception.dart';

/// Hasil pemetaan error autentikasi ke pesan ramah pengguna.
class AuthErrorInfo {
  final String message;
  final String? title;
  final bool isDeviceMismatch;

  const AuthErrorInfo({
    required this.message,
    this.title,
    this.isDeviceMismatch = false,
  });
}

/// Mapper untuk mengubah kode error backend/jaringan menjadi pesan UX yang spesifik.
class AuthErrorMapper {
  AuthErrorMapper._();

  static AuthErrorInfo map(dynamic error) {
    if (error is AppException) {
      return mapCode(error.code, status: error.status);
    }
    return const AuthErrorInfo(
      message: 'Terjadi kesalahan pada sistem. Silakan coba beberapa saat lagi.',
    );
  }

  static AuthErrorInfo mapCode(String code, {int? status}) {
    switch (code) {
      case 'ERR_INVALID_CREDENTIALS':
        return const AuthErrorInfo(
          title: 'Tidak dapat masuk',
          message: 'Username/NIM atau password salah. Periksa kembali data Anda.',
        );
      case 'ERR_DEVICE_MISMATCH':
        return const AuthErrorInfo(
          title: 'Perangkat tidak sesuai',
          message:
              'Login ditolak: akun ini atau perangkat ini sudah terikat. Hubungi Admin untuk reset Device ID.',
          isDeviceMismatch: true,
        );
      case 'ERR_ACCOUNT_INACTIVE':
        return const AuthErrorInfo(
          message: 'Akun tidak aktif. Hubungi Admin.',
        );
      case 'ERR_DEVICE_ID_REQUIRED':
        return const AuthErrorInfo(
          message: 'Device ID tidak terbaca. Hubungi Admin.',
        );
      case 'ERR_TOO_MANY_REQUESTS':
        return const AuthErrorInfo(
          message: 'Terlalu banyak percobaan. Coba lagi sebentar.',
        );
      case 'ERR_VALIDATION':
        return const AuthErrorInfo(
          message: 'Data tidak valid.',
        );
      case 'ERR_TIMEOUT':
      case 'ERR_CONNECTION':
      case 'ERR_NETWORK':
        return const AuthErrorInfo(
          message: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
        );
      default:
        if (status == 429) {
          return const AuthErrorInfo(
            message: 'Terlalu banyak percobaan. Coba lagi sebentar.',
          );
        }
        return const AuthErrorInfo(
          message: 'Terjadi kesalahan pada sistem. Silakan coba beberapa saat lagi.',
        );
    }
  }
}
