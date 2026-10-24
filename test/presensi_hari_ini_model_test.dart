import 'package:flutter_test/flutter_test.dart';
import 'package:geo_jamaah/features/mahasantri/domain/presensi_hari_ini_model.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('PresensiHariIniModel - Parsing Sesuai API_CONTRACT', () {
    test('berhasil parsing data lengkap dari JSON API_CONTRACT', () {
      final json = {
        'tanggal': '2026-10-19',
        'masjid': {
          'id_masjid': 'uuid-masjid-01',
          'nama_masjid': 'Masjid Al-Ikhlas',
          'latitude': -6.2146,
          'longitude': 106.8451,
          'radius_toleransi': 100,
        },
        'jadwal': [
          {
            'id_jadwal': 'uuid-subuh',
            'nama_sholat': 'Subuh',
            'waktu_azan': '04:30',
            'waktu_iqamah': '04:35',
            'waktu_mulai_presensi': '04:20',
            'waktu_akhir_presensi': '05:00',
            'status': 'Hadir',
            'sedang_dalam_window': false,
          },
          {
            'id_jadwal': 'uuid-dzuhur',
            'nama_sholat': 'Dzuhur',
            'waktu_azan': '11:50',
            'waktu_iqamah': '11:55',
            'waktu_mulai_presensi': '11:40',
            'waktu_akhir_presensi': '12:30',
            'status': 'Belum',
            'sedang_dalam_window': true,
          },
        ],
      };

      final response = PresensiHariIniResponse.fromJson(json);

      expect(response.tanggal, '2026-10-19');
      expect(response.masjid, isNotNull);
      expect(response.masjid!.idMasjid, 'uuid-masjid-01');
      expect(response.masjid!.namaMasjid, 'Masjid Al-Ikhlas');
      expect(response.masjid!.latitude, -6.2146);
      expect(response.masjid!.longitude, 106.8451);
      expect(response.masjid!.radiusToleransi, 100);

      expect(response.jadwal.length, 2);

      // Subuh
      final subuh = response.jadwal[0];
      expect(subuh.idJadwal, 'uuid-subuh');
      expect(subuh.namaSholat, 'Subuh');
      expect(subuh.waktuAzan, '04:30');
      expect(subuh.rentangPresensi, '04:20 - 05:00');
      expect(subuh.status, StatusPresensiJadwal.hadir);
      expect(subuh.sedangDalamWindow, false);
      expect(subuh.bisaPresensi, false);
      expect(subuh.keteranganNetral, isNull);

      // Dzuhur (aktif presensi)
      final dzuhur = response.jadwal[1];
      expect(dzuhur.idJadwal, 'uuid-dzuhur');
      expect(dzuhur.namaSholat, 'Dzuhur');
      expect(dzuhur.status, StatusPresensiJadwal.belum);
      expect(dzuhur.sedangDalamWindow, true);
      expect(dzuhur.bisaPresensi, true);
      expect(dzuhur.keteranganNetral, isNull);
    });

    test('berhasil parsing saat masjid bernilai null (masjid belum diatur)', () {
      final json = {
        'tanggal': '2026-10-19',
        'masjid': null,
        'jadwal': [],
      };

      final response = PresensiHariIniResponse.fromJson(json);

      expect(response.tanggal, '2026-10-19');
      expect(response.masjid, isNull);
      expect(response.jadwal, isEmpty);
    });

    test('berhasil parsing saat jadwal kosong []', () {
      final json = {
        'tanggal': '2026-10-19',
        'masjid': {
          'id_masjid': 'uuid-1',
          'nama_masjid': 'Masjid Kampus',
          'latitude': 0.0,
          'longitude': 0.0,
          'radius_toleransi': 50,
        },
        'jadwal': [],
      };

      final response = PresensiHariIniResponse.fromJson(json);

      expect(response.jadwal, isEmpty);
    });
  });

  group('StatusPresensiJadwal - Pemetaan Status Aman & Tampilan', () {
    test('memetakan seluruh status standar dengan benar', () {
      expect(StatusPresensiJadwal.fromString('Hadir'), StatusPresensiJadwal.hadir);
      expect(StatusPresensiJadwal.fromString('Tidak_Hadir'), StatusPresensiJadwal.tidakHadir);
      expect(StatusPresensiJadwal.fromString('tidakhadir'), StatusPresensiJadwal.tidakHadir);
      expect(StatusPresensiJadwal.fromString('Izin'), StatusPresensiJadwal.izin);
      expect(StatusPresensiJadwal.fromString('Manual'), StatusPresensiJadwal.manual);
      expect(StatusPresensiJadwal.fromString('Belum'), StatusPresensiJadwal.belum);
    });

    test('menangani nilai status tak dikenal secara aman dengan unknown', () {
      expect(StatusPresensiJadwal.fromString('RandomStatus'), StatusPresensiJadwal.unknown);
      expect(StatusPresensiJadwal.fromString(null), StatusPresensiJadwal.unknown);
      expect(StatusPresensiJadwal.fromString(''), StatusPresensiJadwal.unknown);
    });

    test('logika penonjolan tombol presensi (bisaPresensi)', () {
      // 1. Status Belum + dalam window -> TRUE
      const jadwalAktif = JadwalHariIniModel(
        idJadwal: '1',
        namaSholat: 'Ashar',
        waktuAzan: '15:15',
        waktuIqamah: '15:20',
        waktuMulaiPresensi: '15:05',
        waktuAkhirPresensi: '15:45',
        status: StatusPresensiJadwal.belum,
        sedangDalamWindow: true,
      );
      expect(jadwalAktif.bisaPresensi, true);
      expect(jadwalAktif.keteranganNetral, isNull);

      // 2. Status Hadir + dalam window -> FALSE
      const jadwalSudahHadir = JadwalHariIniModel(
        idJadwal: '2',
        namaSholat: 'Ashar',
        waktuAzan: '15:15',
        waktuIqamah: '15:20',
        waktuMulaiPresensi: '15:05',
        waktuAkhirPresensi: '15:45',
        status: StatusPresensiJadwal.hadir,
        sedangDalamWindow: true,
      );
      expect(jadwalSudahHadir.bisaPresensi, false);
      expect(jadwalSudahHadir.keteranganNetral, isNull);

      // 3. Status Belum + di luar window -> FALSE dengan keterangan netral
      const jadwalBelumMulai = JadwalHariIniModel(
        idJadwal: '3',
        namaSholat: 'Maghrib',
        waktuAzan: '17:55',
        waktuIqamah: '18:00',
        waktuMulaiPresensi: '17:45',
        waktuAkhirPresensi: '18:25',
        status: StatusPresensiJadwal.belum,
        sedangDalamWindow: false,
      );
      expect(jadwalBelumMulai.bisaPresensi, false);
      expect(jadwalBelumMulai.keteranganNetral, 'Di luar waktu presensi');
    });

    test('format tanggal Indonesia menghasilkan nama hari dan bulan', () {
      const response = PresensiHariIniResponse(
        tanggal: '2026-10-19',
        jadwal: [],
      );
      expect(response.formattedTanggalIndonesia, 'Senin, 19 Oktober 2026');

      const responseFallback = PresensiHariIniResponse(
        tanggal: 'bukan-tanggal-valid',
        jadwal: [],
      );
      expect(responseFallback.formattedTanggalIndonesia, 'bukan-tanggal-valid');
    });
  });
}
