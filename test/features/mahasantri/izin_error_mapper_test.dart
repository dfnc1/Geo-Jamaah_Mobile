import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/mahasantri/domain/izin_error_mapper.dart';

void main() {
  group('IzinErrorMapper - Pemetaan Kode Error Izin ke Pesan Ramah', () {
    test('ERR_VALIDATION memetakan data izin tidak valid', () {
      const err = AppException(
        code: 'ERR_VALIDATION',
        message: 'Validation failed',
        status: 400,
      );
      expect(
        IzinErrorMapper.map(err),
        'Data izin yang dikirim tidak valid. Periksa kembali jenis izin, tanggal, dan alasan.',
      );
    });

    test('ERR_UNAUTHORIZED memetakan sesi kedaluwarsa', () {
      const err = AppException(
        code: 'ERR_UNAUTHORIZED',
        message: 'Token expired',
        status: 401,
      );
      expect(
        IzinErrorMapper.map(err),
        'Sesi Anda telah berakhir. Silakan login kembali.',
      );
    });

    test('ERR_FORBIDDEN_ROLE memetakan akses ditolak non-Mahasantri', () {
      const err = AppException(
        code: 'ERR_FORBIDDEN_ROLE',
        message: 'Forbidden',
        status: 403,
      );
      expect(
        IzinErrorMapper.map(err),
        'Akses ditolak: Hanya Mahasantri yang dapat mengajukan izin.',
      );
    });

    test('ERR_MAHASANTRI_NOT_FOUND memetakan profil tidak ditemukan', () {
      const err = AppException(
        code: 'ERR_MAHASANTRI_NOT_FOUND',
        message: 'Mahasantri not found',
        status: 404,
      );
      expect(
        IzinErrorMapper.map(err),
        'Data profil Mahasantri Anda tidak ditemukan.',
      );
    });

    test('ERR_IZIN_NOT_FOUND memetakan izin tidak ditemukan', () {
      const err = AppException(
        code: 'ERR_IZIN_NOT_FOUND',
        message: 'Izin not found',
        status: 404,
      );
      expect(
        IzinErrorMapper.map(err),
        'Data izin tidak ditemukan.',
      );
    });

    test('ERR_IZIN_ALREADY_DECIDED memetakan izin sudah final', () {
      const err = AppException(
        code: 'ERR_IZIN_ALREADY_DECIDED',
        message: 'Already decided',
        status: 409,
      );
      expect(
        IzinErrorMapper.map(err),
        'Izin sudah diputuskan dan tidak dapat diubah lagi.',
      );
    });

    test('HTTP 429 dan ERR_TOO_MANY_REQUESTS memetakan rate limit', () {
      const errStatus = AppException(
        code: 'ERR_SERVER',
        message: 'Too many requests',
        status: 429,
      );
      expect(
        IzinErrorMapper.map(errStatus),
        'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
      );

      const errCode = AppException(
        code: 'ERR_TOO_MANY_REQUESTS',
        message: 'Throttled',
      );
      expect(
        IzinErrorMapper.map(errCode),
        'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
      );
    });

    test('Jaringan dan timeout memetakan koneksi internet', () {
      const errConn = AppException(
        code: 'ERR_CONNECTION',
        message: 'Connection failed',
      );
      expect(
        IzinErrorMapper.map(errConn),
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );

      const errTimeout = AppException(
        code: 'ERR_TIMEOUT',
        message: 'Timeout exceeded',
      );
      expect(
        IzinErrorMapper.map(errTimeout),
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    });

    test('Kode error tidak dikenal tidak membocorkan kode mentah', () {
      const errUnknown = AppException(
        code: 'ERR_SOME_UNEXPECTED_INTERNAL_ERROR',
        message: 'ERR_SOME_UNEXPECTED_INTERNAL_ERROR',
        status: 500,
      );
      final mapped = IzinErrorMapper.map(errUnknown);
      expect(mapped.contains('ERR_'), false);
      expect(mapped, 'Terjadi kesalahan pada server. Silakan coba lagi nanti.');
    });

    test('Error non-AppException mengembalikan pesan generik', () {
      final mapped = IzinErrorMapper.map(Exception('something'));
      expect(mapped, 'Terjadi kesalahan saat memproses izin. Silakan coba lagi.');
    });
  });
}
