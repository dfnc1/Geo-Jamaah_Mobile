import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/features/admin/domain/admin_models.dart';

void main() {
  group('AdminRekap JSON Deserialization', () {
    test('berhasil mem-parsing JSON rekap global dari API_CONTRACT', () {
      final json = {
        'jumlah_santri_aktif': 3,
        'presensi': {
          'hadir': 28,
          'tidak_hadir': 5,
          'izin': 3,
          'manual': 0,
          'total': 36
        },
        'izin': {
          'pending': 10,
          'disetujui': 4,
          'ditolak': 1,
          'total': 15
        },
        'jumlah_santri_kritis': 0,
      };

      final rekap = AdminRekap.fromJson(json);

      expect(rekap.jumlahSantriAktif, 3);
      expect(rekap.jumlahSantriKritis, 0);

      expect(rekap.presensi.hadir, 28);
      expect(rekap.presensi.tidakHadir, 5);
      expect(rekap.presensi.izin, 3);
      expect(rekap.presensi.manual, 0);
      expect(rekap.presensi.total, 36);

      expect(rekap.izin.pending, 10);
      expect(rekap.izin.disetujui, 4);
      expect(rekap.izin.ditolak, 1);
      expect(rekap.izin.total, 15);
    });

    test('menangani data kosong / default secara aman', () {
      final rekap = AdminRekap.fromJson({});
      expect(rekap.jumlahSantriAktif, 0);
      expect(rekap.jumlahSantriKritis, 0);
      expect(rekap.presensi.total, 0);
      expect(rekap.izin.total, 0);
    });
  });

  group('ResetDeviceResult JSON Deserialization', () {
    test('berhasil mem-parsing respons reset-device sukses', () {
      final json = {
        'nim': '24050505050',
        'nama': 'Ahmad Fauzi',
        'username': 'mahasantri1',
        'device_id': null,
      };

      final res = ResetDeviceResult.fromJson(json);

      expect(res.nim, '24050505050');
      expect(res.nama, 'Ahmad Fauzi');
      expect(res.username, 'mahasantri1');
      expect(res.deviceId, isNull);
    });
  });

  group('JobTandaiResult JSON Deserialization', () {
    test('berhasil mem-parsing respons pemicu job sukses', () {
      final json = {
        'tanggal': '2026-10-17',
        'id_jadwal': null,
        'dibuat': {'Tidak_Hadir': 5, 'Izin': 5},
        'total_dibuat': 10,
      };

      final res = JobTandaiResult.fromJson(json);

      expect(res.tanggal, '2026-10-17');
      expect(res.idJadwal, isNull);
      expect(res.tidakHadir, 5);
      expect(res.izin, 5);
      expect(res.totalDibuat, 10);
    });
  });

  group('ActivityLogResponse JSON Deserialization', () {
    test('berhasil mem-parsing daftar log audit dan paginasi', () {
      final json = {
        'logs': [
          {
            'id_log': 'uuid-1',
            'username': 'admin',
            'role': 'Admin',
            'modul': 'Masjid',
            'aktivitas': 'Mengubah masjid Al-Ikhlas',
            'created_at': '2026-10-18T14:59:28.044Z',
          },
          {
            'id_log': 'uuid-2',
            'username': 'mahasantri1',
            'role': 'Mahasantri',
            'modul': 'Presensi',
            'aktivitas': 'Melakukan presensi shalat Shubuh',
            'created_at': '2026-10-18T05:00:00.000Z',
          }
        ],
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': 2,
          'total_pages': 1,
        }
      };

      final res = ActivityLogResponse.fromJson(json);

      expect(res.logs.length, 2);
      expect(res.logs[0].idLog, 'uuid-1');
      expect(res.logs[0].username, 'admin');
      expect(res.logs[0].role, 'Admin');
      expect(res.logs[0].modul, 'Masjid');
      expect(res.logs[0].aktivitas, 'Mengubah masjid Al-Ikhlas');
      expect(res.logs[0].createdAt, '2026-10-18T14:59:28.044Z');

      expect(res.page, 1);
      expect(res.limit, 20);
      expect(res.total, 2);
      expect(res.totalPages, 1);
    });
  });
}
