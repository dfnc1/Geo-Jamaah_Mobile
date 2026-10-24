import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/auth/domain/auth_error_mapper.dart';

void main() {
  group('AuthErrorMapper - Pemetaan Kode Error ke Pesan UX', () {
    test('ERR_INVALID_CREDENTIALS memetakan ke judul dan pesan kredensial salah', () {
      const exception = AppException(
        code: 'ERR_INVALID_CREDENTIALS',
        message: 'Invalid credentials from server',
        status: 401,
      );

      final errorInfo = AuthErrorMapper.map(exception);

      expect(errorInfo.title, equals('Tidak dapat masuk'));
      expect(
        errorInfo.message,
        equals('Username/NIM atau password salah. Periksa kembali data Anda.'),
      );
      expect(errorInfo.isDeviceMismatch, isFalse);
    });

    test('ERR_DEVICE_MISMATCH memetakan ke flag modal dialog isDeviceMismatch = true', () {
      const exception = AppException(
        code: 'ERR_DEVICE_MISMATCH',
        message: 'Device mismatch from server',
        status: 401,
      );

      final errorInfo = AuthErrorMapper.map(exception);

      expect(errorInfo.title, equals('Perangkat tidak sesuai'));
      expect(
        errorInfo.message,
        equals(
          'Login Ditolak: Akun Anda sudah terikat pada perangkat smartphone lain. Hubungi Admin untuk reset Device ID.',
        ),
      );
      expect(errorInfo.isDeviceMismatch, isTrue);
    });

    test('ERR_ACCOUNT_INACTIVE memetakan ke akun tidak aktif', () {
      const exception = AppException(
        code: 'ERR_ACCOUNT_INACTIVE',
        message: 'Account inactive',
        status: 403,
      );

      final errorInfo = AuthErrorMapper.map(exception);

      expect(errorInfo.message, equals('Akun tidak aktif. Hubungi Admin.'));
      expect(errorInfo.isDeviceMismatch, isFalse);
    });

    test('ERR_DEVICE_ID_REQUIRED memetakan ke device id tidak terbaca', () {
      const exception = AppException(
        code: 'ERR_DEVICE_ID_REQUIRED',
        message: 'device_id required',
        status: 400,
      );

      final errorInfo = AuthErrorMapper.map(exception);

      expect(errorInfo.message, equals('Device ID tidak terbaca. Hubungi Admin.'));
    });

    test('ERR_TOO_MANY_REQUESTS atau status 429 memetakan ke pembatasan rate limit', () {
      const exceptionCode = AppException(
        code: 'ERR_TOO_MANY_REQUESTS',
        message: 'Too many requests',
        status: 429,
      );
      final info1 = AuthErrorMapper.map(exceptionCode);
      expect(info1.message, equals('Terlalu banyak percobaan. Coba lagi sebentar.'));

      const exceptionStatus = AppException(
        code: 'UNKNOWN_RATE_LIMIT',
        message: 'Rate limit',
        status: 429,
      );
      final info2 = AuthErrorMapper.map(exceptionStatus);
      expect(info2.message, equals('Terlalu banyak percobaan. Coba lagi sebentar.'));
    });

    test('ERR_VALIDATION memetakan ke data tidak valid', () {
      const exception = AppException(
        code: 'ERR_VALIDATION',
        message: 'Validation failed',
        status: 400,
      );

      final errorInfo = AuthErrorMapper.map(exception);

      expect(errorInfo.message, equals('Data tidak valid.'));
    });

    test('ERR_TIMEOUT / ERR_CONNECTION / ERR_NETWORK memetakan ke pesan koneksi', () {
      for (final code in ['ERR_TIMEOUT', 'ERR_CONNECTION', 'ERR_NETWORK']) {
        final exception = AppException(code: code, message: 'Network failed');
        final errorInfo = AuthErrorMapper.map(exception);
        expect(
          errorInfo.message,
          equals('Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
        );
      }
    });

    test('Kode error tidak dikenal menghasilkan pesan umum tanpa mengekspos kode mentah', () {
      const exception = AppException(
        code: 'ERR_DATABASE_DEADLOCK_500',
        message: 'Internal raw stack trace',
        status: 500,
      );

      final errorInfo = AuthErrorMapper.map(exception);

      expect(
        errorInfo.message,
        equals('Terjadi kesalahan pada sistem. Silakan coba beberapa saat lagi.'),
      );
      expect(errorInfo.message.contains('ERR_DATABASE_DEADLOCK_500'), isFalse);
    });
  });
}
