import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/musyrif/domain/musyrif_error_mapper.dart';

void main() {
  group('MusyrifErrorMapper', () {
    test('ERR_FORBIDDEN_ROLE memetakan akses ditolak non-Musyrif', () {
      const err = AppException(
        code: 'ERR_FORBIDDEN_ROLE',
        message: 'Forbidden',
        status: 403,
      );
      expect(
        MusyrifErrorMapper.map(err),
        'Akses ditolak: Hanya Musyrif yang dapat mengakses fitur ini.',
      );
    });

    test('ERR_MUSYRIF_NOT_FOUND memetakan profil tidak ditemukan', () {
      const err = AppException(
        code: 'ERR_MUSYRIF_NOT_FOUND',
        message: 'Not found',
        status: 404,
      );
      expect(
        MusyrifErrorMapper.map(err),
        'Profil Musyrif tidak ditemukan.',
      );
    });

    test('ERR_NOT_YOUR_STUDENT memetakan bukan santri binaan', () {
      const err = AppException(
        code: 'ERR_NOT_YOUR_STUDENT',
        message: 'Not your student',
        status: 403,
      );
      expect(
        MusyrifErrorMapper.map(err),
        'Ini bukan santri binaan Anda.',
      );
    });

    test('ERR_IZIN_ALREADY_DECIDED memetakan izin sudah diputuskan', () {
      const err = AppException(
        code: 'ERR_IZIN_ALREADY_DECIDED',
        message: 'Already decided',
        status: 409,
      );
      expect(
        MusyrifErrorMapper.map(err),
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
        MusyrifErrorMapper.map(errStatus),
        'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
      );
      const errCode = AppException(
        code: 'ERR_TOO_MANY_REQUESTS',
        message: 'Throttled',
      );
      expect(
        MusyrifErrorMapper.map(errCode),
        'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
      );
    });

    test('Jaringan dan timeout memetakan koneksi internet', () {
      const err = AppException(
        code: 'ERR_CONNECTION',
        message: 'Connection failed',
      );
      expect(
        MusyrifErrorMapper.map(err),
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    });

    test('Kode error tidak dikenal tidak membocorkan kode mentah', () {
      const errUnknown = AppException(
        code: 'ERR_SOME_UNEXPECTED_INTERNAL_ERROR',
        message: 'ERR_SOME_UNEXPECTED_INTERNAL_ERROR',
        status: 500,
      );
      final mapped = MusyrifErrorMapper.map(errUnknown);
      expect(mapped.contains('ERR_'), false);
      expect(mapped, 'Terjadi kesalahan pada server. Silakan coba lagi nanti.');
    });
  });
}
