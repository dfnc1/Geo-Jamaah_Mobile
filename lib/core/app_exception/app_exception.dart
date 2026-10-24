/// Model exception terpusat untuk aplikasi Geo-Jamaah.
/// Mengonversi error dari server (format {success, statusCode, message, error})
/// atau error jaringan menjadi objek terstruktur.
class AppException implements Exception {
  final String code;
  final String message;
  final int? status;
  final dynamic details;

  const AppException({
    required this.code,
    required this.message,
    this.status,
    this.details,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message, status: $status)';
}
