import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/admin/domain/admin_error_mapper.dart';

void main() {
  group('AdminErrorMapper', () {
    test('ERR_MAHASANTRI_NOT_FOUND memetakan santri tidak ditemukan', () {
      const err = AppException(
        code: 'ERR_MAHASANTRI_NOT_FOUND',
        message: 'Mahasantri not found',
        status: 404,
      );
      expect(
        AdminErrorMapper.map(err),
        'Mahasantri dengan NIM tersebut tidak ditemukan.',
      );
    });

    test('ERR_TIME_WINDOW_INVALID memetakan waktu presensi belum lewat', () {
      const err = AppException(
        code: 'ERR_TIME_WINDOW_INVALID',
        message: 'Window not over',
        status: 400,
      );
      expect(
        AdminErrorMapper.map(err),
        'Waktu akhir presensi jadwal ini belum lewat.',
      );
    });

    test('ERR_FORBIDDEN_ROLE memetakan akses ditolak', () {
      const err = AppException(
        code: 'ERR_FORBIDDEN_ROLE',
        message: 'Forbidden',
        status: 403,
      );
      expect(
        AdminErrorMapper.map(err),
        'Akses ditolak: Anda tidak memiliki hak akses Admin.',
      );
    });

    test('ERR_VALIDATION memetakan input tidak valid', () {
      const err = AppException(
        code: 'ERR_VALIDATION',
        message: 'Validation failed',
        status: 400,
      );
      expect(
        AdminErrorMapper.map(err),
        'Data atau parameter yang dimasukkan tidak valid.',
      );
    });

    test('exception umum mengembalikan pesan default', () {
      final err = Exception('Random exception');
      expect(
        AdminErrorMapper.map(err),
        'Terjadi kesalahan. Silakan coba lagi.',
      );
    });
  });
}
