import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/core/app_exception/app_exception.dart';
import 'package:geo_jamaah/features/presensi/domain/presensi_error_mapper.dart';

void main() {
  group('PresensiErrorMapper - Pemetaan Seluruh Kode Error ke Pesan Ramah', () {
    test('ERR_GEOFENCE_RADIUS_EXCEEDED memetakan pesan tetap (bukan message server mentah)', () {
      const errWithMsg = AppException(
        code: 'ERR_GEOFENCE_RADIUS_EXCEEDED',
        message: 'Jarak Anda 120.5 m dari masjid, melebihi radius 100 m',
        status: 400,
      );
      expect(
        PresensiErrorMapper.map(errWithMsg),
        'Anda berada di luar radius area masjid yang diizinkan.',
      );

      const errDefault = AppException(
        code: 'ERR_GEOFENCE_RADIUS_EXCEEDED',
        message: '',
        status: 400,
      );
      expect(
        PresensiErrorMapper.map(errDefault),
        'Anda berada di luar radius area masjid yang diizinkan.',
      );
    });

    test('ERR_TIME_WINDOW_INVALID memetakan pesan tetap (bukan message server mentah)', () {
      const err = AppException(
        code: 'ERR_TIME_WINDOW_INVALID',
        message: 'Di luar window presensi shalat',
        status: 400,
      );
      expect(
        PresensiErrorMapper.map(err),
        'Saat ini berada di luar rentang waktu presensi untuk jadwal shalat ini.',
      );

      const errEmpty = AppException(
        code: 'ERR_TIME_WINDOW_INVALID',
        message: '',
        status: 400,
      );
      expect(
        PresensiErrorMapper.map(errEmpty),
        'Saat ini berada di luar rentang waktu presensi untuk jadwal shalat ini.',
      );
    });

    test('ERR_MOCK_LOCATION memetakan pesan fake GPS', () {
      const err = AppException(
        code: 'ERR_MOCK_LOCATION',
        message: 'Fake GPS terdeteksi',
        status: 400,
      );
      expect(
        PresensiErrorMapper.map(err),
        'Terdeteksi lokasi palsu (Fake GPS). Harap nonaktifkan aplikasi lokasi tiruan lalu coba lagi.',
      );
    });

    test('ERR_GPS_ACCURACY_LOW memetakan pesan akurasi rendah', () {
      const err = AppException(
        code: 'ERR_GPS_ACCURACY_LOW',
        message: 'Akurasi tidak cukup',
        status: 400,
      );
      expect(
        PresensiErrorMapper.map(err),
        'Akurasi GPS kurang baik (> 50 m). Pindah ke area terbuka lalu coba lagi.',
      );
    });

    test('ERR_ALREADY_PRESENT memetakan pesan sudah presensi netral', () {
      const err = AppException(
        code: 'ERR_ALREADY_PRESENT',
        message: 'Sudah tercatat',
        status: 409,
      );
      expect(
        PresensiErrorMapper.map(err),
        'Anda sudah presensi untuk shalat ini.',
      );
    });

    test('ERR_JADWAL_NOT_FOUND memetakan jadwal tidak ditemukan', () {
      const err = AppException(
        code: 'ERR_JADWAL_NOT_FOUND',
        message: 'Jadwal not found',
        status: 404,
      );
      expect(
        PresensiErrorMapper.map(err),
        'Data jadwal shalat tidak ditemukan di server.',
      );
    });

    test('ERR_MASJID_NOT_FOUND memetakan masjid tidak ditemukan', () {
      const err = AppException(
        code: 'ERR_MASJID_NOT_FOUND',
        message: 'Masjid not found',
        status: 404,
      );
      expect(
        PresensiErrorMapper.map(err),
        'Data masjid tidak ditemukan di server.',
      );
    });

    test('ERR_VALIDATION memetakan data tidak valid', () {
      const err = AppException(
        code: 'ERR_VALIDATION',
        message: 'Validation failed',
        status: 400,
      );
      expect(
        PresensiErrorMapper.map(err),
        'Data presensi yang dikirim tidak valid. Silakan coba lagi.',
      );
    });

    test('HTTP 429 dan ERR_TOO_MANY_REQUESTS memetakan rate limit', () {
      const errStatus = AppException(
        code: 'ERR_SERVER',
        message: 'Too many requests',
        status: 429,
      );
      expect(
        PresensiErrorMapper.map(errStatus),
        'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
      );

      const errCode = AppException(
        code: 'ERR_TOO_MANY_REQUESTS',
        message: 'Throttled',
      );
      expect(
        PresensiErrorMapper.map(errCode),
        'Terlalu banyak permintaan. Silakan tunggu beberapa saat lalu coba lagi.',
      );
    });

    test('Jaringan dan timeout memetakan koneksi internet', () {
      const errConn = AppException(
        code: 'ERR_CONNECTION',
        message: 'Connection failed',
      );
      expect(
        PresensiErrorMapper.map(errConn),
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );

      const errTimeout = AppException(
        code: 'ERR_TIMEOUT',
        message: 'Timeout exceeded',
      );
      expect(
        PresensiErrorMapper.map(errTimeout),
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    });

    test('Kode error tidak dikenal tidak membocorkan kode mentah', () {
      const errUnknown = AppException(
        code: 'ERR_SOME_UNEXPECTED_INTERNAL_ERROR',
        message: 'ERR_SOME_UNEXPECTED_INTERNAL_ERROR',
        status: 500,
      );
      final mapped = PresensiErrorMapper.map(errUnknown);
      expect(mapped.contains('ERR_'), false);
      expect(mapped, 'Terjadi kesalahan pada server. Silakan coba lagi nanti.');
    });
  });
}
